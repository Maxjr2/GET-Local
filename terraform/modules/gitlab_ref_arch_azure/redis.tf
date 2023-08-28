module "redis" {
  source = "../gitlab_azure_instance"

  prefix          = var.prefix
  node_type       = "redis"
  node_count      = var.redis_node_count
  additional_tags = var.additional_tags

  size                   = var.redis_size
  source_image_reference = var.source_image_reference
  disk_size              = coalesce(var.redis_disk_size, var.default_disk_size)
  storage_account_type   = coalesce(var.redis_storage_account_type, var.default_storage_account_type)

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

output "redis" {
  value = module.redis
}

# Redis Separated

module "redis_cache" {
  source = "../gitlab_azure_instance"

  prefix          = var.prefix
  node_type       = "redis-cache"
  node_count      = var.redis_cache_node_count
  additional_tags = var.additional_tags

  size                   = var.redis_cache_size
  source_image_reference = var.source_image_reference
  disk_size              = coalesce(var.redis_cache_disk_size, var.default_disk_size)
  storage_account_type   = coalesce(var.redis_cache_storage_account_type, var.default_storage_account_type)

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

output "redis_cache" {
  value = module.redis_cache
}

module "redis_persistent" {
  source = "../gitlab_azure_instance"

  prefix          = var.prefix
  node_type       = "redis-persistent"
  node_count      = var.redis_persistent_node_count
  additional_tags = var.additional_tags

  size                   = var.redis_persistent_size
  source_image_reference = var.source_image_reference
  disk_size              = coalesce(var.redis_persistent_disk_size, var.default_disk_size)
  storage_account_type   = coalesce(var.redis_persistent_storage_account_type, var.default_storage_account_type)

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

output "redis_persistent" {
  value = module.redis_persistent
}
