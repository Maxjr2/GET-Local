locals {
  opensearch_service_subnet_ids = local.backend_subnet_ids != null ? local.backend_subnet_ids : slice(tolist(local.default_subnet_ids), 0, var.opensearch_service_default_subnet_count)
}

resource "aws_iam_service_linked_role" "gitlab_opensearch_role" {
  count = var.opensearch_service_linked_role_create ? min(var.opensearch_service_node_count, 1) : 0

  aws_service_name = "opensearchservice.amazonaws.com"
}

resource "aws_opensearch_domain" "gitlab" {
  count = min(var.opensearch_service_node_count, 1)

  domain_name    = format("%.28s", var.prefix)
  engine_version = var.opensearch_service_engine_version

  cluster_config {
    instance_count = var.opensearch_service_node_count
    instance_type  = "${var.opensearch_service_instance_type}.search"

    dedicated_master_enabled = var.opensearch_service_master_node_count != null ? true : false
    dedicated_master_count   = var.opensearch_service_master_node_count
    dedicated_master_type    = var.opensearch_service_master_instance_type != null ? "${var.opensearch_service_master_instance_type}.search" : null

    warm_enabled = var.opensearch_service_warm_node_count != null ? true : false
    warm_count   = var.opensearch_service_warm_node_count
    warm_type    = var.opensearch_service_warm_instance_type

    zone_awareness_enabled = var.opensearch_service_multi_az
    zone_awareness_config {
      availability_zone_count = length(local.opensearch_service_subnet_ids) >= 3 ? 3 : 2
    }
  }

  vpc_options {
    subnet_ids = local.opensearch_service_subnet_ids

    security_group_ids = [aws_security_group.gitlab_opensearch_service[0].id]
  }

  ebs_options {
    ebs_enabled = true
    volume_type = var.opensearch_service_volume_type
    volume_size = var.opensearch_service_volume_size
    iops        = var.opensearch_service_volume_iops
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  encrypt_at_rest {
    enabled    = true
    kms_key_id = var.opensearch_service_kms_key_arn != null ? var.opensearch_service_kms_key_arn : var.default_kms_key_arn
  }

  node_to_node_encryption {
    enabled = true
  }

  tags = merge({
    Domain = var.prefix
  }, var.opensearch_service_tags)

  depends_on = [aws_iam_service_linked_role.gitlab_opensearch_role[0]]
}

# Note - Security policy applies VPC limit in security.tf
resource "aws_opensearch_domain_policy" "gitlab_opensearch_policy" {
  count = min(var.opensearch_service_node_count, 1)

  domain_name = aws_opensearch_domain.gitlab[0].domain_name

  access_policies = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "es:*"
        Principal = "*",
        Effect    = "Allow"
        Resource  = "${aws_opensearch_domain.gitlab[0].arn}/*"
      }
    ]
  })
}

output "opensearch_service" {
  value = {
    "opensearch_host"           = try("https://${aws_opensearch_domain.gitlab[0].endpoint}", "")
    "opensearch_domain_name"    = try(aws_opensearch_domain.gitlab[0].domain_name, "")
    "opensearch_kms_key_arn"    = try(aws_opensearch_domain.gitlab[0].encrypt_at_rest[0].kms_key_id, "")
    "opensearch_engine_version" = try(aws_opensearch_domain.gitlab[0].engine_version, "")
  }
}
