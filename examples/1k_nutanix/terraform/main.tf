terraform {
  backend "local" {}

  required_providers {
    nutanix = {
      source  = "nutanix/nutanix"
      version = "~> 2.4"
    }
  }
}

provider "nutanix" {
  endpoint = var.nutanix_endpoint
  username = var.nutanix_username
  password = var.nutanix_password
  insecure = var.nutanix_insecure
}
