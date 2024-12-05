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
variable "disk_kms_key" {
  type    = string
  default = null
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
variable "service_account_profiles" {
  description = "The role for this service account, or null. Depending on the role, the account may be granted special access rights"
  type        = list(string)
  default     = []
}
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account_iam#member/members
variable "service_account_user_members" {
  description = "List of optional identity members that will be assigned the Service Account User role on each created Service Account, which is required to attach the service accounts to resources. List must contain the identity running Terraform if given. If not given account running Terraform will be given sole access."

  type    = list(string)
  default = []
}
variable "custom_service_account_email" {
  type        = string
  default     = null
  description = "Service account to use for this GCP instance. If not supplied, one will be created"
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
variable "custom_labels" {
  type    = map(string)
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

## TODO: additional_labels is deprecated and will be removed in 4.x
variable "additional_labels" {
  description = "Deprecated. Replaced by custom_labels."
  type        = map(any)
  default     = {}
}
