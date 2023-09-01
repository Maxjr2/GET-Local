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

# Azure
variable "source_image_reference" {
  type = map(any)
  default = {
    "publisher" = "Canonical"
    "offer"     = "0001-com-ubuntu-server-focal"
    "sku"       = "20_04-lts"
    "version"   = "latest"
  }
}

variable "location" {
  type    = string
  default = "East US 2"
}
variable "storage_account_name" {
  type    = string
  default = null
}
variable "resource_group_name" {
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
variable "external_ip_type" {
  type    = string
  default = "Basic"
}

variable "default_disk_size" {
  type    = string
  default = "100"
}
variable "default_storage_account_type" {
  type    = string
  default = "Standard_LRS"
}

variable "object_storage_buckets" {
  type    = list(string)
  default = ["artifacts", "backups", "dependency-proxy", "lfs", "mr-diffs", "packages", "terraform-state", "uploads", "registry", "ci-secure-files"]
}
variable "object_storage_prefix" {
  type    = string
  default = null
}

variable "additional_tags" {
  type    = map(any)
  default = {}
}

# Machines
variable "consul_node_count" {
  type    = number
  default = 0
}
variable "consul_size" {
  type    = string
  default = ""
}
variable "consul_storage_account_type" {
  type    = string
  default = null
}
variable "consul_disk_size" {
  type    = string
  default = null
}

variable "gitaly_node_count" {
  type    = number
  default = 0
}
variable "gitaly_size" {
  type    = string
  default = ""
}
variable "gitaly_storage_account_type" {
  type    = string
  default = "Premium_LRS"
}
variable "gitaly_disk_size" {
  type    = string
  default = "4095"
}

variable "gitlab_nfs_node_count" {
  type    = number
  default = 0
}
variable "gitlab_nfs_size" {
  type    = string
  default = ""
}
variable "gitlab_nfs_storage_account_type" {
  type    = string
  default = null
}
variable "gitlab_nfs_disk_size" {
  type    = string
  default = null
}

variable "gitlab_rails_node_count" {
  type    = number
  default = 0
}
variable "gitlab_rails_size" {
  type    = string
  default = ""
}
variable "gitlab_rails_storage_account_type" {
  type    = string
  default = null
}
variable "gitlab_rails_disk_size" {
  type    = string
  default = null
}

variable "haproxy_external_node_count" {
  type    = number
  default = 0
}
variable "haproxy_external_size" {
  type    = string
  default = ""
}
variable "haproxy_external_storage_account_type" {
  type    = string
  default = null
}
variable "haproxy_external_disk_size" {
  type    = string
  default = null
}
variable "haproxy_external_external_ip_names" {
  type    = list(string)
  default = []
}

variable "haproxy_internal_node_count" {
  type    = number
  default = 0
}
variable "haproxy_internal_size" {
  type    = string
  default = ""
}
variable "haproxy_internal_storage_account_type" {
  type    = string
  default = null
}
variable "haproxy_internal_disk_size" {
  type    = string
  default = null
}

variable "monitor_node_count" {
  type    = number
  default = 0
}
variable "monitor_size" {
  type    = string
  default = ""
}
variable "monitor_storage_account_type" {
  type    = string
  default = null
}
variable "monitor_disk_size" {
  type    = string
  default = null
}

variable "pgbouncer_node_count" {
  type    = number
  default = 0
}
variable "pgbouncer_size" {
  type    = string
  default = ""
}
variable "pgbouncer_storage_account_type" {
  type    = string
  default = null
}
variable "pgbouncer_disk_size" {
  type    = string
  default = null
}

variable "postgres_node_count" {
  type    = number
  default = 0
}
variable "postgres_size" {
  type    = string
  default = ""
}
variable "postgres_storage_account_type" {
  type    = string
  default = null
}
variable "postgres_disk_size" {
  type    = string
  default = null
}

variable "praefect_node_count" {
  type    = number
  default = 0
}
variable "praefect_size" {
  type    = string
  default = ""
}
variable "praefect_storage_account_type" {
  type    = string
  default = null
}
variable "praefect_disk_size" {
  type    = string
  default = null
}

variable "praefect_postgres_node_count" {
  type    = number
  default = 0
}
variable "praefect_postgres_size" {
  type    = string
  default = ""
}
variable "praefect_postgres_storage_account_type" {
  type    = string
  default = null
}
variable "praefect_postgres_disk_size" {
  type    = string
  default = null
}

variable "redis_node_count" {
  type    = number
  default = 0
}
variable "redis_size" {
  type    = string
  default = ""
}
variable "redis_storage_account_type" {
  type    = string
  default = null
}
variable "redis_disk_size" {
  type    = string
  default = null
}

variable "redis_cache_node_count" {
  type    = number
  default = 0
}
variable "redis_cache_size" {
  type    = string
  default = ""
}
variable "redis_cache_storage_account_type" {
  type    = string
  default = null
}
variable "redis_cache_disk_size" {
  type    = string
  default = null
}

variable "redis_persistent_node_count" {
  type    = number
  default = 0
}
variable "redis_persistent_size" {
  type    = string
  default = ""
}
variable "redis_persistent_storage_account_type" {
  type    = string
  default = null
}
variable "redis_persistent_disk_size" {
  type    = string
  default = null
}

variable "sidekiq_node_count" {
  type    = number
  default = 0
}
variable "sidekiq_size" {
  type    = string
  default = ""
}
variable "sidekiq_storage_account_type" {
  type    = string
  default = null
}
variable "sidekiq_disk_size" {
  type    = string
  default = null
}

#Networking

variable "vnet_address_space" {
  type    = list(string)
  default = ["172.16.0.0/12"]
}
variable "subnet_address_ranges" {
  type    = list(string)
  default = ["172.17.0.0/16"]
}

## Default network
variable "default_allowed_ingress_cidr_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "http_allowed_ingress_cidr_blocks" {
  type    = list(any)
  default = []
}

variable "ssh_allowed_ingress_cidr_blocks" {
  type    = list(any)
  default = []
}

variable "external_ssh_port" {
  type    = number
  default = 2222
}
variable "external_ssh_allowed_ingress_cidr_blocks" {
  type    = list(any)
  default = []
}

variable "icmp_allowed_ingress_cidr_blocks" {
  type    = list(any)
  default = []
}

## External IPs
variable "setup_external_ips" {
  type    = bool
  default = true
}

variable "nat_gateway_idle_timeout_in_minutes" {
  type    = number
  default = 4
}
