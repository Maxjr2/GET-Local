module "gitlab_ref_arch_nutanix" {
  source = "../../modules/gitlab_ref_arch_nutanix"

  prefix                 = var.prefix
  cluster_uuid           = var.cluster_uuid
  subnet_uuid            = var.subnet_uuid
  image_uuid             = var.image_uuid
  storage_container_uuid = var.storage_container_uuid
  vm_admin_username      = var.vm_admin_username
  ssh_public_key         = file(var.ssh_public_key_file_path)

  # 1k
  gitlab_rails_node_count = 1
  gitlab_rails_size = {
    num_sockets          = 4
    num_vcpus_per_socket = 2
    memory_size_mib      = 8192
  }
}

output "gitlab_ref_arch_nutanix" {
  value = module.gitlab_ref_arch_nutanix
}
