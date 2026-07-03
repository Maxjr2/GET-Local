module "gitlab_nfs" {
  source = "../gitlab_nutanix_instance"

  prefix     = var.prefix
  node_type  = "gitlab-nfs"
  node_count = var.gitlab_nfs_node_count

  custom_categories = var.gitlab_nfs_custom_categories

  size       = coalesce(var.gitlab_nfs_size, var.default_size)
  disk_size  = coalesce(var.gitlab_nfs_disk_size, var.default_disk_size)
  data_disks = var.gitlab_nfs_data_disks

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

output "gitlab_nfs" {
  value = module.gitlab_nfs
}
