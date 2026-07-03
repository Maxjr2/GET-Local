variable "prefix" {
  type = string
}

variable "node_type" {
  type = string
}

variable "cluster_uuid" {
  type = string
}

variable "subnet_uuid" {
  type = string
}

variable "image_uuid" {
  type = string
}

variable "storage_container_uuid" {
  type = string
}

variable "ssh_public_key" {
  type = string
}

variable "vm_admin_username" {
  type = string
}

variable "node_count" {
  type    = number
  default = 1
}

variable "size" {
  type = object({
    num_sockets          = number
    num_vcpus_per_socket = number
    memory_size_mib      = number
  })
  default = {
    num_sockets          = 2
    num_vcpus_per_socket = 1
    memory_size_mib      = 8192
  }
}

variable "disk_size" {
  description = "Boot disk size in GB"
  type        = string
  default     = "100"
}

variable "label_secondaries" {
  type    = bool
  default = false
}

variable "geo_site" {
  type    = string
  default = null
}

variable "geo_deployment" {
  type    = string
  default = null
}

variable "custom_categories" {
  description = "Map of additional Nutanix category name/value pairs to apply. The category names must already exist (e.g. created via nutanix_category_key in the calling module)."
  type        = map(string)
  default     = {}
}

variable "data_disks" {
  type = list(
    object({
      name                   = string,
      size                   = optional(number),
      storage_container_uuid = optional(string),
      index                  = number
    })
  )
  default = []
}
