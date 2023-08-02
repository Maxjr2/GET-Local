module "gitlab_rails" {
  source = "../gitlab_aws_instance"

  prefix          = var.prefix
  node_type       = "gitlab-rails"
  node_count      = var.gitlab_rails_node_count
  additional_tags = var.additional_tags

  instance_type              = var.gitlab_rails_instance_type
  ami_id                     = var.ami_id != null ? var.ami_id : data.aws_ami.ubuntu_default[0].id
  disk_size                  = coalesce(var.gitlab_rails_disk_size, var.default_disk_size)
  disk_type                  = coalesce(var.gitlab_rails_disk_type, var.default_disk_type)
  disk_encrypt               = coalesce(var.gitlab_rails_disk_encrypt, var.default_disk_encrypt)
  disk_kms_key_arn           = var.gitlab_rails_disk_kms_key_arn != null ? var.gitlab_rails_disk_kms_key_arn : var.default_kms_key_arn
  disk_delete_on_termination = var.gitlab_rails_disk_delete_on_termination != null ? var.gitlab_rails_disk_delete_on_termination : var.default_disk_delete_on_termination
  data_disks                 = var.gitlab_rails_data_disks
  subnet_ids                 = local.backend_subnet_ids

  iam_instance_policy_arns = flatten([
    local.gitlab_s3_policy_create ? [aws_iam_policy.gitlab_s3_policy[0].arn] : [],
    local.gitlab_s3_backups_policy_create ? [aws_iam_policy.gitlab_s3_backups_policy[0].arn] : [],
    local.gitlab_s3_registry_policy_create ? [aws_iam_policy.gitlab_s3_registry_policy[0].arn] : [],
    local.gitlab_s3_kms_policy_create ? [aws_iam_policy.gitlab_s3_kms_policy[0].arn] : [],
    var.default_iam_instance_policy_arns,
    var.gitlab_rails_iam_instance_policy_arns
  ])
  iam_identifier_path          = var.default_iam_identifier_path
  iam_permissions_boundary_arn = var.default_iam_permissions_boundary_arn

  ssh_key_name = try(aws_key_pair.ssh_key[0].key_name, null)
  security_group_ids = flatten([
    aws_security_group.gitlab_internal_networking.id,
    try(aws_security_group.gitlab_external_ssh[0].id, null),
    var.gitlab_rails_security_group_ids
  ])

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment

  label_secondaries = true
}

output "gitlab_rails" {
  value = module.gitlab_rails
}
