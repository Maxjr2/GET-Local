# General
variable "prefix" {
  type    = string
  default = null
}
variable "geo_site" {
  type    = string
  default = null
}
variable "geo_deployment" {
  type    = string
  default = null
}

# Nutanix
variable "cluster_uuid" {
  type    = string
  default = null
}
variable "subnet_uuid" {
  type    = string
  default = null
}
variable "image_uuid" {
  type    = string
  default = null
}
variable "storage_container_uuid" {
  type    = string
  default = null
}
variable "vm_admin_username" {
  type    = string
  default = null
}
variable "ssh_public_key" {
  type    = string
  default = null
}

variable "default_disk_size" {
  type    = string
  default = "100"
}
variable "default_size" {
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

# Machines
variable "consul_node_count" {
  type    = number
  default = 0
}
variable "consul_size" {
  type    = object({ num_sockets = number, num_vcpus_per_socket = number, memory_size_mib = number })
  default = null
}
variable "consul_disk_size" {
  type    = string
  default = null
}
variable "consul_data_disks" {
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
variable "consul_custom_categories" {
  type    = map(string)
  default = {}
}

variable "gitaly_node_count" {
  type    = number
  default = 0
}
variable "gitaly_size" {
  type    = object({ num_sockets = number, num_vcpus_per_socket = number, memory_size_mib = number })
  default = null
}
variable "gitaly_disk_size" {
  type    = string
  default = "4095"
}
variable "gitaly_data_disks" {
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
variable "gitaly_custom_categories" {
  type    = map(string)
  default = {}
}

variable "gitlab_nfs_node_count" {
  type    = number
  default = 0
}
variable "gitlab_nfs_size" {
  type    = object({ num_sockets = number, num_vcpus_per_socket = number, memory_size_mib = number })
  default = null
}
variable "gitlab_nfs_disk_size" {
  type    = string
  default = null
}
variable "gitlab_nfs_data_disks" {
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
variable "gitlab_nfs_custom_categories" {
  type    = map(string)
  default = {}
}

variable "gitlab_rails_node_count" {
  type    = number
  default = 0
}
variable "gitlab_rails_size" {
  type    = object({ num_sockets = number, num_vcpus_per_socket = number, memory_size_mib = number })
  default = null
}
variable "gitlab_rails_disk_size" {
  type    = string
  default = null
}
variable "gitlab_rails_data_disks" {
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
variable "gitlab_rails_custom_categories" {
  type    = map(string)
  default = {}
}

variable "haproxy_external_node_count" {
  type    = number
  default = 0
}
variable "haproxy_external_size" {
  type    = object({ num_sockets = number, num_vcpus_per_socket = number, memory_size_mib = number })
  default = null
}
variable "haproxy_external_disk_size" {
  type    = string
  default = null
}
variable "haproxy_external_data_disks" {
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
variable "haproxy_external_custom_categories" {
  type    = map(string)
  default = {}
}

variable "haproxy_internal_node_count" {
  type    = number
  default = 0
}
variable "haproxy_internal_size" {
  type    = object({ num_sockets = number, num_vcpus_per_socket = number, memory_size_mib = number })
  default = null
}
variable "haproxy_internal_disk_size" {
  type    = string
  default = null
}
variable "haproxy_internal_data_disks" {
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
variable "haproxy_internal_custom_categories" {
  type    = map(string)
  default = {}
}

variable "monitor_node_count" {
  type    = number
  default = 0
}
variable "monitor_size" {
  type    = object({ num_sockets = number, num_vcpus_per_socket = number, memory_size_mib = number })
  default = null
}
variable "monitor_disk_size" {
  type    = string
  default = null
}
variable "monitor_data_disks" {
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
variable "monitor_custom_categories" {
  type    = map(string)
  default = {}
}

variable "opensearch_vm_node_count" {
  type    = number
  default = 0
}
variable "opensearch_vm_size" {
  type    = object({ num_sockets = number, num_vcpus_per_socket = number, memory_size_mib = number })
  default = null
}
variable "opensearch_vm_disk_size" {
  type    = string
  default = null
}
variable "opensearch_vm_data_disks" {
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
variable "opensearch_vm_custom_categories" {
  type    = map(string)
  default = {}
}

variable "pgbouncer_node_count" {
  type    = number
  default = 0
}
variable "pgbouncer_size" {
  type    = object({ num_sockets = number, num_vcpus_per_socket = number, memory_size_mib = number })
  default = null
}
variable "pgbouncer_disk_size" {
  type    = string
  default = null
}
variable "pgbouncer_data_disks" {
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
variable "pgbouncer_custom_categories" {
  type    = map(string)
  default = {}
}

variable "postgres_node_count" {
  type    = number
  default = 0
}
variable "postgres_size" {
  type    = object({ num_sockets = number, num_vcpus_per_socket = number, memory_size_mib = number })
  default = null
}
variable "postgres_disk_size" {
  type    = string
  default = null
}
variable "postgres_data_disks" {
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
variable "postgres_custom_categories" {
  type    = map(string)
  default = {}
}

variable "praefect_node_count" {
  type    = number
  default = 0
}
variable "praefect_size" {
  type    = object({ num_sockets = number, num_vcpus_per_socket = number, memory_size_mib = number })
  default = null
}
variable "praefect_disk_size" {
  type    = string
  default = null
}
variable "praefect_data_disks" {
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
variable "praefect_custom_categories" {
  type    = map(string)
  default = {}
}

variable "praefect_postgres_node_count" {
  type    = number
  default = 0
}
variable "praefect_postgres_size" {
  type    = object({ num_sockets = number, num_vcpus_per_socket = number, memory_size_mib = number })
  default = null
}
variable "praefect_postgres_disk_size" {
  type    = string
  default = null
}
variable "praefect_postgres_data_disks" {
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
variable "praefect_postgres_custom_categories" {
  type    = map(string)
  default = {}
}

variable "redis_node_count" {
  type    = number
  default = 0
}
variable "redis_size" {
  type    = object({ num_sockets = number, num_vcpus_per_socket = number, memory_size_mib = number })
  default = null
}
variable "redis_disk_size" {
  type    = string
  default = null
}
variable "redis_data_disks" {
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
variable "redis_custom_categories" {
  type    = map(string)
  default = {}
}

variable "redis_cache_node_count" {
  type    = number
  default = 0
}
variable "redis_cache_size" {
  type    = object({ num_sockets = number, num_vcpus_per_socket = number, memory_size_mib = number })
  default = null
}
variable "redis_cache_disk_size" {
  type    = string
  default = null
}
variable "redis_cache_data_disks" {
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
variable "redis_cache_custom_categories" {
  type    = map(string)
  default = {}
}

variable "redis_persistent_node_count" {
  type    = number
  default = 0
}
variable "redis_persistent_size" {
  type    = object({ num_sockets = number, num_vcpus_per_socket = number, memory_size_mib = number })
  default = null
}
variable "redis_persistent_disk_size" {
  type    = string
  default = null
}
variable "redis_persistent_data_disks" {
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
variable "redis_persistent_custom_categories" {
  type    = map(string)
  default = {}
}

variable "sidekiq_node_count" {
  type    = number
  default = 0
}
variable "sidekiq_size" {
  type    = object({ num_sockets = number, num_vcpus_per_socket = number, memory_size_mib = number })
  default = null
}
variable "sidekiq_disk_size" {
  type    = string
  default = null
}
variable "sidekiq_data_disks" {
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
variable "sidekiq_custom_categories" {
  type    = map(string)
  default = {}
}
