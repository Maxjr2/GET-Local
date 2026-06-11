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

variable "elastic_ip_allocation_ids" {
  type    = list(string)
  default = []
}

variable "ami_id" {
  type    = string
  default = null
}

variable "iam_instance_policy_arns" {
  type    = list(string)
  default = []
}

variable "iam_permissions_boundary_arn" {
  type    = string
  default = null
}

variable "iam_identifier_path" {
  type    = string
  default = null
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "security_group_ids" {
  type    = list(string)
  default = []
}

variable "ssh_key_name" {
  type    = string
  default = null
}

variable "disk_type" {
  type    = string
  default = "gp3"
}

variable "disk_size" {
  type    = string
  default = "100"
}

variable "disk_iops" {
  type    = number
  default = null
}
variable "disk_throughput" {
  type    = number
  default = null
}

variable "disk_encrypt" {
  type    = bool
  default = false
}

variable "disk_kms_key_arn" {
  type    = string
  default = null
}

variable "data_disks" {
  type = list(
    object({ name = string, device_name = string, type = optional(string), size = optional(number), iops = optional(number), throughput = optional(number), skip_destroy = optional(bool), source_snapshots = optional(map(string)), snapshots = optional(map(string)) })
  )
  default = []
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

variable "subnet_ids" {
  type    = list(string)
  default = null
}

variable "disk_delete_on_termination" {
  type    = bool
  default = null
}

variable "user_data_base64" {
  type        = string
  default     = null
  description = "Custom EC2 user data. See https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html for more information"
}

variable "custom_tags" {
  type    = map(any)
  default = {}
}

variable "set_name_tags" {
  type        = bool
  default     = true
  description = "Whether to set the 'Name' tag on resources. If false, ensure dynamic inventory uses 'tag:gitlab_node_name' instead of 'tag:Name'"
}

variable "metadata_options" {
  description = "EC2 instance metadata options"
  type = object({
    http_endpoint               = optional(string, "enabled")
    http_put_response_hop_limit = optional(number, 1)
    instance_metadata_tags      = optional(string, "enabled")
    http_protocol_ipv6          = optional(string, "disabled")
  })
  default = {}
}

# Deprecated: var.additional_tags is superseded by var.custom_tags.
variable "additional_tags" {
  description = "Deprecated. Replaced by custom_tags."
  type        = map(any)
  default     = {}
}
