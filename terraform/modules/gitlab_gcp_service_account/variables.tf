variable "custom_service_account_email" {
  description = "Provided ID for the service account, if it was created outside of GET"
  type        = string
  default     = null
  nullable    = true
}

variable "account_id" {
  description = "Account ID of Service Account to be created if configured"
  type        = string
  nullable    = false
}

variable "display_name" {
  description = "Display name of Service Account to be created if configured"
  type        = string
}

variable "service_account_profiles" {
  description = "A set of access types required for this service account (or none)."
  type        = list(string)
  default     = []
  nullable    = false

  validation {
    condition = alltrue([
      for profile in var.service_account_profiles :
      contains([
        "object_storage"
        # Additional required access types will added here over time
      ], profile)
    ])
    error_message = "Service account profile must be one of 'object_storage'."
  }
}
