variable "prefix" {
  type = string
}

variable "node_type" {
  type = string
}
variable "node_count" {
  type    = number
  default = 1
}

variable "machine_type" {
  type    = string
  default = "n1-standard-2"
}
variable "machine_image" {
  type    = string
  default = "ubuntu-2004-lts"
}

variable "disk_size" {
  type    = string
  default = "100"
}
variable "disk_type" {
  type    = string
  default = "pd-standard"
}

variable "label_secondaries" {
  type    = bool
  default = false
}

variable "service_account_iam_scopes" {
  type    = list(string)
  default = ["cloud-platform"] # https://cloud.google.com/compute/docs/access/create-enable-service-accounts-for-instances#best_practices
}
variable "service_account_prefix" {
  type    = string
  default = "gl"

  validation {
    condition     = length(var.service_account_prefix) <= 10 && can(regex("[a-z]([-a-z0-9]*[a-z0-9])", var.service_account_prefix))
    error_message = "service_account_prefix must be 10 characters or less and only contain lowercase alphanumeric characters and dashes."
  }
}

variable "geo_site" {
  type    = string
  default = null
}
variable "geo_deployment" {
  type    = string
  default = null
}

variable "disks" {
  type    = list(any)
  default = []
}

variable "vpc" {
  type    = string
  default = "default"
}
variable "subnet" {
  type    = string
  default = "default"
}
variable "zones" {
  type    = list(any)
  default = null
}
variable "external_ips" {
  type    = list(string)
  default = []
}
variable "setup_external_ip" {
  type    = bool
  default = true
}

variable "name_override" {
  type    = string
  default = null
}
variable "tags" {
  type    = list(string)
  default = []
}
variable "additional_labels" {
  type    = map(any)
  default = {}
}

variable "allow_stopping_for_update" {
  type    = bool
  default = true
}
variable "machine_secure_boot" {
  type    = bool
  default = false
}
