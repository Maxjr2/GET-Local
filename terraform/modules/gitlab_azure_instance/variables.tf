variable "prefix" {
  type = string
}

variable "node_type" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "ssh_public_key" {
  type = string
}

variable "vm_admin_username" {
  type = string
}

variable "location" {
  type    = string
  default = "eastus2"
}

variable "node_count" {
  type    = number
  default = 1
}

variable "external_ip_names" {
  type    = list(string)
  default = []
}

variable "external_ip_type" {
  type    = string
  default = "Basic"
}

variable "setup_external_ip" {
  type    = bool
  default = true
}

variable "size" {
  type    = string
  default = "Standard_D2s_v3"
}

variable "source_image_reference" {
  type = map(any)
  default = {
    "publisher" = "Canonical"
    "offer"     = "ubuntu-24_04-lts"
    "sku"       = "server"
    "version"   = "latest"
  }
}

variable "disk_size" {
  type    = string
  default = "100"
}

variable "storage_account_type" {
  type    = string
  default = "Standard_LRS"
}

variable "label_secondaries" {
  type    = bool
  default = false
}

variable "application_security_group" {
  type    = any # Resouce passthrough is object of undetermined types so any is required
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

variable "custom_tags" {
  type    = map(any)
  default = {}
}

# TODO: additional_tags is deprecated and will be removed in 4.x
variable "additional_tags" {
  description = "Deprecated. Replaced by custom_tags."
  type        = map(any)
  default     = {}
}

variable "data_disks" {
  type = list(
    object({
      name                 = string,
      size                 = optional(number),
      storage_account_type = optional(string),
      lun                  = number,
      caching              = optional(string),
      tier                 = optional(string)
    })
  )
  default = []
}
