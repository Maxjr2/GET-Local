# EKS
data "aws_partition" "current" {}

locals {
  aws_partition = data.aws_partition.current.partition

  total_node_pool_count = var.webservice_node_pool_count + var.sidekiq_node_pool_count + var.supporting_node_pool_count + var.webservice_node_pool_max_count + var.sidekiq_node_pool_max_count + var.supporting_node_pool_max_count

  webservice_node_pool_autoscaling = var.webservice_node_pool_max_count > 0
  sidekiq_node_pool_autoscaling    = var.sidekiq_node_pool_max_count > 0
  supporting_node_pool_autoscaling = var.supporting_node_pool_max_count > 0

  # Subnet selection
  eks_default_subnet_ids      = local.default_network ? slice(tolist(local.default_subnet_ids), 0, var.eks_default_subnet_count) : []
  eks_cluster_subnet_ids      = !local.default_network ? local.all_subnet_ids : local.eks_default_subnet_ids
  eks_backend_node_subnet_ids = !local.default_network ? local.backend_subnet_ids : local.eks_default_subnet_ids

  # AMI selection
  eks_ami_type                   = var.eks_ami_id != null ? "CUSTOM" : "AL2_x86_64"
  eks_node_group_release_version = var.eks_ami_id != null ? null : (var.eks_node_group_ami_release_version == "latest" ? nonsensitive(data.aws_ssm_parameter.eks_ami_release_version[0].value) : var.eks_node_group_ami_release_version)
}

# Cluster
resource "aws_eks_cluster" "gitlab_cluster" {
  count = min(local.total_node_pool_count, 1)

  name                      = var.prefix
  version                   = var.eks_version
  role_arn                  = aws_iam_role.gitlab_eks_role[0].arn
  enabled_cluster_log_types = var.eks_enabled_cluster_log_types

  vpc_config {
    endpoint_public_access = var.eks_endpoint_public_access
    public_access_cidrs    = var.eks_endpoint_public_access_cidr_blocks

    endpoint_private_access = true
    subnet_ids              = local.eks_cluster_subnet_ids

    security_group_ids = [
      aws_security_group.gitlab_internal_networking.id,
    ]
  }

  dynamic "encryption_config" {
    for_each = range(var.eks_envelope_encryption ? 1 : 0)

    content {
      provider {
        key_arn = var.eks_envelope_kms_key_arn != null ? var.eks_envelope_kms_key_arn : coalesce(var.default_kms_key_arn, try(aws_kms_key.gitlab_cluster_key[0].arn, null))
      }
      resources = ["secrets"]
    }
  }

  tags = merge({
    gitlab_node_prefix = var.prefix
    gitlab_node_type   = "gitlab-cluster"
  }, var.additional_tags)

  depends_on = [
    aws_iam_role_policy_attachment.gitlab_eks_role_cluster_policy,
    aws_iam_role_policy_attachment.gitlab_eks_role_vpc_resource_controller_policy,
  ]
}

## Optional KMS Key for EKS Envelope Encryption if enabled and none provided (deprecated)
## kics: Terraform AWS - KMS Key With Vulnerable Policy - Key is deprecated and will be removed in future
## kics-scan ignore-block
resource "aws_kms_key" "gitlab_cluster_key" {
  count = var.eks_envelope_encryption && local.total_node_pool_count > 0 && var.eks_envelope_kms_key_arn == null && var.default_kms_key_arn == null ? 1 : 0

  description         = "${var.prefix}-cluster-key"
  enable_key_rotation = true
}

## Optional KMS Key for EKS Envelope Encryption if enabled and none provided
resource "aws_kms_alias" "gitlab_cluster_key" {
  count = var.eks_envelope_encryption && local.total_node_pool_count > 0 && var.eks_envelope_kms_key_arn == null && var.default_kms_key_arn == null ? 1 : 0

  name          = "alias/${var.prefix}-cluster-key"
  target_key_id = aws_kms_key.gitlab_cluster_key[0].arn
}

# Node Pools
## Default EKS AL2 Release Version
data "aws_ssm_parameter" "eks_ami_release_version" {
  count = var.eks_node_group_ami_release_version == "latest" ? min(local.total_node_pool_count, 1) : 0

  name = "/aws/service/eks/optimized-ami/${aws_eks_cluster.gitlab_cluster[0].version}/amazon-linux-2/recommended/release_version"
}

## Webservice
resource "aws_launch_template" "gitlab_webservice" {
  count = min(var.webservice_node_pool_count + var.webservice_node_pool_max_count, 1)

  name = "${var.prefix}-eks-webservice-launch-template"

  instance_type = var.webservice_node_pool_instance_type
  image_id      = var.eks_ami_id

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = coalesce(var.webservice_node_pool_disk_size, var.default_disk_size)
      volume_type           = var.default_disk_type
      encrypted             = true
      delete_on_termination = true
    }
  }

  vpc_security_group_ids = [
    aws_eks_cluster.gitlab_cluster[0].vpc_config[0].cluster_security_group_id,
    aws_security_group.gitlab_internal_networking.id,
  ]

  # Enforce IMDSv2 - https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template#metadata-options
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge({
      Name               = "${var.prefix}-webservice-node-pool"
      gitlab_node_prefix = var.prefix
      gitlab_node_type   = "gitlab-webservice-node-pool"
    }, var.additional_tags)
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge({
      Name = "${var.prefix}-webservice-pool-root"
    }, var.additional_tags)
  }

  update_default_version = true

  user_data = var.eks_ami_id != null ? base64encode(templatefile("${path.module}/templates/userdata.sh.tpl", { cluster_name = aws_eks_cluster.gitlab_cluster[0].name })) : null
}

resource "aws_eks_node_group" "gitlab_webservice_pool" {
  count = min(var.webservice_node_pool_count + var.webservice_node_pool_max_count, 1)

  node_group_name_prefix = "${format("%.25s", var.prefix)}-webservice-" # Create a unique name to allow nodepool replacements
  cluster_name           = aws_eks_cluster.gitlab_cluster[0].name
  subnet_ids             = local.eks_backend_node_subnet_ids
  node_role_arn          = aws_iam_role.gitlab_eks_node_role[0].arn

  launch_template {
    id      = aws_launch_template.gitlab_webservice[0].id
    version = aws_launch_template.gitlab_webservice[0].latest_version
  }
  ami_type        = local.eks_ami_type
  release_version = local.eks_node_group_release_version

  scaling_config {
    desired_size = local.webservice_node_pool_autoscaling ? var.webservice_node_pool_min_count : var.webservice_node_pool_count
    min_size     = local.webservice_node_pool_autoscaling ? var.webservice_node_pool_min_count : var.webservice_node_pool_count
    max_size     = local.webservice_node_pool_autoscaling ? var.webservice_node_pool_max_count : var.webservice_node_pool_count
  }

  labels = {
    workload = "webservice"
  }

  tags = merge({
    gitlab_node_prefix = var.prefix
    gitlab_node_type   = "gitlab-webservice-node-pool"

    "k8s.io/cluster-autoscaler/${aws_eks_cluster.gitlab_cluster[0].name}" = "owned"
    "k8s.io/cluster-autoscaler/enabled"                                   = "true"
  }, var.additional_tags)

  # Ensure that IAM Role policies and Addons are created beforehand as required by Node Pool
  depends_on = [
    aws_iam_role_policy_attachment.gitlab_eks_node_role_node_policy,
    aws_iam_role_policy_attachment.gitlab_eks_node_role_ec2_container_registry_read_only_policy,
    aws_eks_addon.kube_proxy,
    aws_eks_addon.vpc_cni,
  ]

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      scaling_config[0].desired_size,
    ]
  }
}

## Sidekiq
resource "aws_launch_template" "gitlab_sidekiq" {
  count = min(var.sidekiq_node_pool_count + var.sidekiq_node_pool_max_count, 1)

  name = "${var.prefix}-eks-sidekiq-launch-template"

  instance_type = var.sidekiq_node_pool_instance_type
  image_id      = var.eks_ami_id

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = coalesce(var.sidekiq_node_pool_disk_size, var.default_disk_size)
      volume_type           = var.default_disk_type
      encrypted             = true
      delete_on_termination = true
    }
  }

  vpc_security_group_ids = [
    aws_eks_cluster.gitlab_cluster[0].vpc_config[0].cluster_security_group_id,
    aws_security_group.gitlab_internal_networking.id,
  ]

  # Enforce IMDSv2 - https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template#metadata-options
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge({
      Name               = "${var.prefix}-sidekiq-node-pool"
      gitlab_node_prefix = var.prefix
      gitlab_node_type   = "gitlab-sidekiq-node-pool"
    }, var.additional_tags)
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge({
      Name = "${var.prefix}-sidekiq-pool-root"
    }, var.additional_tags)
  }

  update_default_version = true

  user_data = var.eks_ami_id != null ? base64encode(templatefile("${path.module}/templates/userdata.sh.tpl", { cluster_name = aws_eks_cluster.gitlab_cluster[0].name })) : null
}

resource "aws_eks_node_group" "gitlab_sidekiq_pool" {
  count = min(var.sidekiq_node_pool_count + var.sidekiq_node_pool_max_count, 1)

  node_group_name_prefix = "${format("%.28s", var.prefix)}-sidekiq-" # Create a unique name to allow nodepool replacements
  cluster_name           = aws_eks_cluster.gitlab_cluster[0].name
  subnet_ids             = local.eks_backend_node_subnet_ids
  node_role_arn          = aws_iam_role.gitlab_eks_node_role[0].arn

  launch_template {
    id      = aws_launch_template.gitlab_sidekiq[0].id
    version = aws_launch_template.gitlab_sidekiq[0].latest_version
  }
  ami_type        = local.eks_ami_type
  release_version = local.eks_node_group_release_version

  scaling_config {
    desired_size = local.sidekiq_node_pool_autoscaling ? var.sidekiq_node_pool_min_count : var.sidekiq_node_pool_count
    min_size     = local.sidekiq_node_pool_autoscaling ? var.sidekiq_node_pool_min_count : var.sidekiq_node_pool_count
    max_size     = local.sidekiq_node_pool_autoscaling ? var.sidekiq_node_pool_max_count : var.sidekiq_node_pool_count
  }

  labels = {
    workload = "sidekiq"
  }

  tags = merge({
    gitlab_node_prefix = var.prefix
    gitlab_node_type   = "gitlab-sidekiq-node-pool"

    "k8s.io/cluster-autoscaler/${aws_eks_cluster.gitlab_cluster[0].name}" = "owned"
    "k8s.io/cluster-autoscaler/enabled"                                   = "true"
  }, var.additional_tags)

  # Ensure that IAM Role policies and Addons are created beforehand as required by Node Pool
  depends_on = [
    aws_iam_role_policy_attachment.gitlab_eks_node_role_node_policy,
    aws_iam_role_policy_attachment.gitlab_eks_node_role_ec2_container_registry_read_only_policy,
    aws_eks_addon.kube_proxy,
    aws_eks_addon.vpc_cni,
  ]

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      scaling_config[0].desired_size,
    ]
  }
}

## Supporting
resource "aws_launch_template" "gitlab_supporting" {
  count = min(var.supporting_node_pool_count + var.supporting_node_pool_max_count, 1)

  name = "${var.prefix}-eks-supporting-launch-template"

  instance_type = var.supporting_node_pool_instance_type
  image_id      = var.eks_ami_id

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = coalesce(var.supporting_node_pool_disk_size, var.default_disk_size)
      volume_type           = var.default_disk_type
      encrypted             = true
      delete_on_termination = true
    }
  }

  vpc_security_group_ids = [
    aws_eks_cluster.gitlab_cluster[0].vpc_config[0].cluster_security_group_id,
    aws_security_group.gitlab_internal_networking.id,
  ]

  # Enforce IMDSv2 - https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template#metadata-options
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge({
      Name               = "${var.prefix}-supporting-node-pool"
      gitlab_node_prefix = var.prefix
      gitlab_node_type   = "gitlab-supporting-node-pool"
    }, var.additional_tags)
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge({
      Name = "${var.prefix}-supporting-pool-root"
    }, var.additional_tags)
  }

  update_default_version = true

  user_data = var.eks_ami_id != null ? base64encode(templatefile("${path.module}/templates/userdata.sh.tpl", { cluster_name = aws_eks_cluster.gitlab_cluster[0].name })) : null
}

resource "aws_eks_node_group" "gitlab_supporting_pool" {
  count = min(var.supporting_node_pool_count + var.supporting_node_pool_max_count, 1)

  node_group_name_prefix = "${format("%.25s", var.prefix)}-supporting-" # Create a unique name to allow nodepool replacements
  cluster_name           = aws_eks_cluster.gitlab_cluster[0].name
  subnet_ids             = local.eks_backend_node_subnet_ids
  node_role_arn          = aws_iam_role.gitlab_eks_node_role[0].arn

  launch_template {
    id      = aws_launch_template.gitlab_supporting[0].id
    version = aws_launch_template.gitlab_supporting[0].latest_version
  }
  ami_type        = local.eks_ami_type
  release_version = local.eks_node_group_release_version

  scaling_config {
    desired_size = local.supporting_node_pool_autoscaling ? var.supporting_node_pool_min_count : var.supporting_node_pool_count
    min_size     = local.supporting_node_pool_autoscaling ? var.supporting_node_pool_min_count : var.supporting_node_pool_count
    max_size     = local.supporting_node_pool_autoscaling ? var.supporting_node_pool_max_count : var.supporting_node_pool_count
  }

  labels = {
    workload = "support"
  }

  tags = merge({
    gitlab_node_prefix = var.prefix
    gitlab_node_type   = "gitlab-supporting-node-pool"

    "k8s.io/cluster-autoscaler/${aws_eks_cluster.gitlab_cluster[0].name}" = "owned"
    "k8s.io/cluster-autoscaler/enabled"                                   = "true"
  }, var.additional_tags)

  # Ensure that IAM Role policies and Addons are created beforehand as required by Node Pool
  depends_on = [
    aws_iam_role_policy_attachment.gitlab_eks_node_role_node_policy,
    aws_iam_role_policy_attachment.gitlab_eks_node_role_ec2_container_registry_read_only_policy,
    aws_eks_addon.kube_proxy,
    aws_eks_addon.vpc_cni,
  ]

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      scaling_config[0].desired_size,
    ]
  }
}

# Addons
## kube_proxy
data "aws_eks_addon_version" "kube_proxy" {
  count = var.eks_kube_proxy_version == "latest" ? min(local.total_node_pool_count, 1) : 0

  addon_name         = "kube-proxy"
  kubernetes_version = aws_eks_cluster.gitlab_cluster[0].version
  most_recent        = true
}

resource "aws_eks_addon" "kube_proxy" {
  count = min(local.total_node_pool_count, 1)

  cluster_name  = aws_eks_cluster.gitlab_cluster[0].name
  addon_name    = "kube-proxy"
  addon_version = var.eks_kube_proxy_version == "latest" ? data.aws_eks_addon_version.kube_proxy[0].version : var.eks_kube_proxy_version

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

## coredns
data "aws_eks_addon_version" "coredns" {
  count = var.eks_coredns_version == "latest" ? min(local.total_node_pool_count, 1) : 0

  addon_name         = "coredns"
  kubernetes_version = aws_eks_cluster.gitlab_cluster[0].version
  most_recent        = true
}

resource "aws_eks_addon" "coredns" {
  count = min(local.total_node_pool_count, 1)

  cluster_name  = aws_eks_cluster.gitlab_cluster[0].name
  addon_name    = "coredns"
  addon_version = var.eks_coredns_version == "latest" ? data.aws_eks_addon_version.coredns[0].version : var.eks_coredns_version

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  # Ensure that Nodes are created beforehand as required by addon
  depends_on = [
    aws_eks_node_group.gitlab_webservice_pool,
    aws_eks_node_group.gitlab_sidekiq_pool,
    aws_eks_node_group.gitlab_supporting_pool
  ]
}

## vpc-cni
data "aws_eks_addon_version" "vpc_cni" {
  count = var.eks_vpc_cni_version == "latest" ? min(local.total_node_pool_count, 1) : 0

  addon_name         = "vpc-cni"
  kubernetes_version = aws_eks_cluster.gitlab_cluster[0].version
  most_recent        = true
}

resource "aws_eks_addon" "vpc_cni" {
  count = min(local.total_node_pool_count, 1)

  cluster_name             = aws_eks_cluster.gitlab_cluster[0].name
  addon_name               = "vpc-cni"
  addon_version            = var.eks_vpc_cni_version == "latest" ? data.aws_eks_addon_version.vpc_cni[0].version : var.eks_vpc_cni_version
  service_account_role_arn = aws_iam_role.gitlab_addon_vpc_cni_role[count.index].arn

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  # Ensure that Kube Proxy addon and OpenID provider are created beforehand as required by addon
  depends_on = [
    aws_eks_addon.kube_proxy,
    aws_iam_openid_connect_provider.gitlab_cluster_openid
  ]
}

## ebs_csi_driver
data "aws_eks_addon_version" "ebs_csi_driver" {
  count = var.eks_ebs_csi_driver_version == "latest" ? min(local.total_node_pool_count, 1) : 0

  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = aws_eks_cluster.gitlab_cluster[0].version
  most_recent        = true
}

resource "aws_eks_addon" "ebs_csi_driver" {
  count = min(local.total_node_pool_count, 1)

  cluster_name             = aws_eks_cluster.gitlab_cluster[0].name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = var.eks_ebs_csi_driver_version == "latest" ? data.aws_eks_addon_version.ebs_csi_driver[0].version : var.eks_ebs_csi_driver_version
  service_account_role_arn = aws_iam_role.gitlab_addon_ebs_csi_driver_role[count.index].arn

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  # Ensure that OpenID provider is created beforehand as required by addon
  depends_on = [
    aws_iam_openid_connect_provider.gitlab_cluster_openid
  ]
}

output "kubernetes" {
  value = {
    "kubernetes_cluster_name"    = try(aws_eks_cluster.gitlab_cluster[0].name, "")
    "kubernetes_cluster_version" = try(aws_eks_cluster.gitlab_cluster[0].version, "")

    # Expose All Roles created for EKS
    "kubernetes_eks_role"                    = try(aws_iam_role.gitlab_eks_role[0].name, "")
    "kubernetes_eks_node_role"               = try(aws_iam_role.gitlab_eks_node_role[0].name, "")
    "kubernetes_eks_webservice_role"         = try(aws_iam_role.gitlab_eks_webservice_role[0].name, "")
    "kubernetes_eks_sidekiq_role"            = try(aws_iam_role.gitlab_eks_sidekiq_role[0].name, "")
    "kubernetes_eks_toolbox_role"            = try(aws_iam_role.gitlab_eks_toolbox_role[0].name, "")
    "kubernetes_eks_registry_role"           = try(aws_iam_role.gitlab_eks_registry_role[0].name, "")
    "kubernetes_eks_cluster_autoscaler_role" = try(aws_iam_role.gitlab_eks_cluster_autoscaler_role[0].name, "")
    "kubernetes_addon_vpc_cni_role"          = try(aws_iam_role.gitlab_addon_vpc_cni_role[0].name, "")
    "kubernetes_addon_ebs_csi_driver_role"   = try(aws_iam_role.gitlab_addon_ebs_csi_driver_role[0].name, "")

    # Provide the OIDC information to be used outside of this module (e.g. IAM role for other K8s components)
    "kubernetes_cluster_oidc_issuer_url" = try(aws_eks_cluster.gitlab_cluster[0].identity[0].oidc[0].issuer, "")
    "kubernetes_oidc_provider"           = try(replace(aws_eks_cluster.gitlab_cluster[0].identity[0].oidc[0].issuer, "https://", ""), "")
    "kubernetes_oidc_provider_arn"       = try(aws_iam_openid_connect_provider.gitlab_cluster_openid[0].arn, "")

    # Node Group / Addon Versions
    "kubernetes_webservice_node_group_ami_release_version" = try(aws_eks_node_group.gitlab_webservice_pool[0].release_version, "")
    "kubernetes_sidekiq_node_group_ami_release_version"    = try(aws_eks_node_group.gitlab_sidekiq_pool[0].release_version, "")
    "kubernetes_supporting_node_group_ami_release_version" = try(aws_eks_node_group.gitlab_supporting_pool[0].release_version, "")

    "kubernetes_addon_kube_proxy_version"     = try(aws_eks_addon.kube_proxy[0].addon_version, "")
    "kubernetes_addon_coredns_version"        = try(aws_eks_addon.coredns[0].addon_version, "")
    "kubernetes_addon_vpc_cni_version"        = try(aws_eks_addon.vpc_cni[0].addon_version, "")
    "kubernetes_addon_ebs_csi_driver_version" = try(aws_eks_addon.ebs_csi_driver[0].addon_version, "")
  }
}
