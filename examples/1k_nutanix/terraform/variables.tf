variable "nutanix_endpoint" {
  default = "<prism_central_endpoint>"
}

variable "nutanix_username" {
  default = "<nutanix_username>"
}

variable "nutanix_password" {
  default = "<nutanix_password>"
}

variable "nutanix_insecure" {
  default = false
}

variable "prefix" {
  default = "<environment_prefix>"
}

variable "cluster_uuid" {
  default = "<nutanix_cluster_uuid>"
}

variable "subnet_uuid" {
  default = "<nutanix_subnet_uuid>"
}

variable "image_uuid" {
  default = "<nutanix_image_uuid>"
}

variable "storage_container_uuid" {
  default = "<nutanix_storage_container_uuid>"
}

variable "vm_admin_username" {
  default = "<vm_admin_username>"
}

variable "ssh_public_key_file_path" {
  default = "<public_ssh_key_path>"
}
