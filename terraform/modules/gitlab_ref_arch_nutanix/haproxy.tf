module "haproxy_external" {
  source = "../gitlab_nutanix_instance"

  prefix     = var.prefix
  node_type  = "haproxy-external"
  node_count = var.haproxy_external_node_count

  custom_categories = var.haproxy_external_custom_categories

  size       = coalesce(var.haproxy_external_size, var.default_size)
  disk_size  = coalesce(var.haproxy_external_disk_size, var.default_disk_size)
  data_disks = var.haproxy_external_data_disks

  cluster_uuid           = var.cluster_uuid
  subnet_uuid            = var.subnet_uuid
  image_uuid             = var.image_uuid
  storage_container_uuid = var.storage_container_uuid
  vm_admin_username      = var.vm_admin_username
  ssh_public_key         = var.ssh_public_key

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment

  depends_on = [
    nutanix_category_key.gitlab,
    nutanix_category_value.node_prefix,
    nutanix_category_value.node_type,
    nutanix_category_value.node_level,
    nutanix_category_value.geo_site,
    nutanix_category_value.geo_deployment,
  ]
}

output "haproxy_external" {
  value = module.haproxy_external
}

module "haproxy_internal" {
  source = "../gitlab_nutanix_instance"

  prefix     = var.prefix
  node_type  = "haproxy-internal"
  node_count = var.haproxy_internal_node_count

  custom_categories = var.haproxy_internal_custom_categories

  size       = coalesce(var.haproxy_internal_size, var.default_size)
  disk_size  = coalesce(var.haproxy_internal_disk_size, var.default_disk_size)
  data_disks = var.haproxy_internal_data_disks

  cluster_uuid           = var.cluster_uuid
  subnet_uuid            = var.subnet_uuid
  image_uuid             = var.image_uuid
  storage_container_uuid = var.storage_container_uuid
  vm_admin_username      = var.vm_admin_username
  ssh_public_key         = var.ssh_public_key

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment

  depends_on = [
    nutanix_category_key.gitlab,
    nutanix_category_value.node_prefix,
    nutanix_category_value.node_type,
    nutanix_category_value.node_level,
    nutanix_category_value.geo_site,
    nutanix_category_value.geo_deployment,
  ]
}

output "haproxy_internal" {
  value = module.haproxy_internal
}
