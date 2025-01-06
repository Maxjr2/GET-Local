module "gitlab_rails" {
  source = "../gitlab_azure_instance"

  prefix     = var.prefix
  node_type  = "gitlab-rails"
  node_count = var.gitlab_rails_node_count

  # TODO: var.additional_tags deprecated and will be removed in 4.x
  custom_tags = merge(var.additional_tags, var.custom_tags, var.gitlab_rails_custom_tags)

  size                   = var.gitlab_rails_size
  source_image_reference = var.source_image_reference
  disk_size              = coalesce(var.gitlab_rails_disk_size, var.default_disk_size)
  storage_account_type   = coalesce(var.gitlab_rails_storage_account_type, var.default_storage_account_type)

  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.gitlab.id
  vm_admin_username   = var.vm_admin_username
  ssh_public_key      = var.ssh_public_key
  location            = var.location
  external_ip_type    = var.external_ip_type
  setup_external_ip   = var.setup_external_ips

  external_ip_names          = var.gitlab_rails_external_ip_names
  application_security_group = length(var.gitlab_rails_external_ip_names) > 0 && var.haproxy_external_node_count == 0 ? azurerm_application_security_group.gitlab_rails[0] : azurerm_application_security_group.ssh

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment

  label_secondaries = true
}

output "gitlab_rails" {
  value = module.gitlab_rails
}
