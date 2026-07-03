module "sidekiq" {
  source = "../gitlab_nutanix_instance"

  prefix     = var.prefix
  node_type  = "sidekiq"
  node_count = var.sidekiq_node_count

  custom_categories = var.sidekiq_custom_categories

  size       = coalesce(var.sidekiq_size, var.default_size)
  disk_size  = coalesce(var.sidekiq_disk_size, var.default_disk_size)
  data_disks = var.sidekiq_data_disks

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

output "sidekiq" {
  value = module.sidekiq
}
