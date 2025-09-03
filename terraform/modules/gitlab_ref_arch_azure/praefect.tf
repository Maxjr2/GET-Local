module "praefect" {
  source = "../gitlab_azure_instance"

  prefix     = var.prefix
  node_type  = "praefect"
  node_count = var.praefect_node_count

  # TODO: var.additional_tags is deprecated and will be removed in 4.x
  custom_tags = merge(var.additional_tags, var.custom_tags, var.praefect_custom_tags)

  size                   = var.praefect_size
  source_image_reference = var.source_image_reference
  disk_size              = coalesce(var.praefect_disk_size, var.default_disk_size)
  storage_account_type   = coalesce(var.praefect_storage_account_type, var.default_storage_account_type)
  data_disks             = var.praefect_data_disks

  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.gitlab.id
  vm_admin_username   = var.vm_admin_username
  ssh_public_key      = var.ssh_public_key
  location            = var.location
  external_ip_type    = var.external_ip_type
  setup_external_ip   = var.setup_external_ips

  application_security_group = azurerm_application_security_group.ssh

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment

  label_secondaries = true
}

output "praefect" {
  value = module.praefect
}
