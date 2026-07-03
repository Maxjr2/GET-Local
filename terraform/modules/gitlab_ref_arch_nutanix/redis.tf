module "redis" {
  source = "../gitlab_nutanix_instance"

  prefix     = var.prefix
  node_type  = "redis"
  node_count = var.redis_node_count

  custom_categories = var.redis_custom_categories

  size       = coalesce(var.redis_size, var.default_size)
  disk_size  = coalesce(var.redis_disk_size, var.default_disk_size)
  data_disks = var.redis_data_disks

  cluster_uuid           = var.cluster_uuid
  subnet_uuid            = var.subnet_uuid
  image_uuid             = var.image_uuid
  storage_container_uuid = var.storage_container_uuid
  vm_admin_username      = var.vm_admin_username
  ssh_public_key         = var.ssh_public_key

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment

  label_secondaries = true

  depends_on = [
    nutanix_category_key.gitlab,
    nutanix_category_value.node_prefix,
    nutanix_category_value.node_type,
    nutanix_category_value.node_level,
    nutanix_category_value.geo_site,
    nutanix_category_value.geo_deployment,
  ]
}

output "redis" {
  value = module.redis
}

# Redis Separated

module "redis_cache" {
  source = "../gitlab_nutanix_instance"

  prefix     = var.prefix
  node_type  = "redis-cache"
  node_count = var.redis_cache_node_count

  custom_categories = var.redis_cache_custom_categories

  size       = coalesce(var.redis_cache_size, var.default_size)
  disk_size  = coalesce(var.redis_cache_disk_size, var.default_disk_size)
  data_disks = var.redis_cache_data_disks

  cluster_uuid           = var.cluster_uuid
  subnet_uuid            = var.subnet_uuid
  image_uuid             = var.image_uuid
  storage_container_uuid = var.storage_container_uuid
  vm_admin_username      = var.vm_admin_username
  ssh_public_key         = var.ssh_public_key

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment

  label_secondaries = true

  depends_on = [
    nutanix_category_key.gitlab,
    nutanix_category_value.node_prefix,
    nutanix_category_value.node_type,
    nutanix_category_value.node_level,
    nutanix_category_value.geo_site,
    nutanix_category_value.geo_deployment,
  ]
}

output "redis_cache" {
  value = module.redis_cache
}

module "redis_persistent" {
  source = "../gitlab_nutanix_instance"

  prefix     = var.prefix
  node_type  = "redis-persistent"
  node_count = var.redis_persistent_node_count

  custom_categories = var.redis_persistent_custom_categories

  size       = coalesce(var.redis_persistent_size, var.default_size)
  disk_size  = coalesce(var.redis_persistent_disk_size, var.default_disk_size)
  data_disks = var.redis_persistent_data_disks

  cluster_uuid           = var.cluster_uuid
  subnet_uuid            = var.subnet_uuid
  image_uuid             = var.image_uuid
  storage_container_uuid = var.storage_container_uuid
  vm_admin_username      = var.vm_admin_username
  ssh_public_key         = var.ssh_public_key

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment

  label_secondaries = true

  depends_on = [
    nutanix_category_key.gitlab,
    nutanix_category_value.node_prefix,
    nutanix_category_value.node_type,
    nutanix_category_value.node_level,
    nutanix_category_value.geo_site,
    nutanix_category_value.geo_deployment,
  ]
}

output "redis_persistent" {
  value = module.redis_persistent
}
