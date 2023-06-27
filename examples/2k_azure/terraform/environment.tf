module "gitlab_ref_arch_azure" {
  source = "../../modules/gitlab_ref_arch_azure"

  prefix               = var.prefix
  location             = var.location
  storage_account_name = var.storage_account_name
  resource_group_name  = var.resource_group_name
  vm_admin_username    = var.vm_admin_username
  ssh_public_key       = file(var.ssh_public_key_file_path)
  external_ip_type     = "Standard"

  # 2k
  gitaly_node_count = 1
  gitaly_size       = "Standard_D4s_v3"

  gitlab_rails_node_count = 2
  gitlab_rails_size       = "Standard_F8s_v2"

  haproxy_external_node_count        = 1
  haproxy_external_size              = "Standard_F2s_v2"
  haproxy_external_external_ip_names = [var.external_ip_name]

  monitor_node_count = 1
  monitor_size       = "Standard_F2s_v2"

  postgres_node_count = 1
  postgres_size       = "Standard_D2s_v3"

  redis_node_count = 1
  redis_size       = "Standard_D2s_v3"
}

output "gitlab_ref_arch_azure" {
  value = module.gitlab_ref_arch_azure
}
