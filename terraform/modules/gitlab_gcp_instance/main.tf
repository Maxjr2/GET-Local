terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.77"
    }
  }
}

resource "google_compute_instance" "gitlab" {
  count        = var.node_count
  name         = "${local.name_prefix}-${count.index + 1}"
  machine_type = var.machine_type
  tags         = distinct(concat([var.prefix, var.node_type, "${var.prefix}-${var.node_type}"], var.tags))
  zone         = var.zones == null ? null : element(var.zones, count.index)

  allow_stopping_for_update = var.allow_stopping_for_update

  shielded_instance_config {
    enable_secure_boot = var.machine_secure_boot
  }

  boot_disk {
    initialize_params {
      image = var.machine_image
      size  = var.disk_size
      type  = var.disk_type
    }
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  labels = merge({
    gitlab_node_prefix    = var.prefix
    gitlab_node_type      = var.node_type
    gitlab_node_level     = var.label_secondaries == true ? (count.index == 0 ? "${var.node_type}-primary" : "${var.node_type}-secondary") : ""
    gitlab_geo_site       = var.geo_site
    gitlab_geo_deployment = var.geo_deployment
    gitlab_geo_full_role  = var.geo_site == null ? null : (count.index == 0 ? "${var.geo_site}-${var.node_type}-primary" : "${var.geo_site}-${var.node_type}-secondary")
  }, var.additional_labels)

  network_interface {
    network    = var.vpc
    subnetwork = var.subnet

    dynamic "access_config" {
      # Dynamic block is used here to be able to completely omit it if not needed.
      for_each = var.setup_external_ip ? [local.external_ips[count.index]] : []
      content {
        nat_ip = access_config.value
      }
    }
  }

  service_account {
    email  = google_service_account.gitlab[0].email
    scopes = var.service_account_iam_scopes
  }

  lifecycle {
    ignore_changes = [
      min_cpu_platform,
      boot_disk
    ]
  }

  dynamic "attached_disk" {
    for_each = var.disks
    content {
      source      = google_compute_disk.gitlab["${attached_disk.value["device_name"]}-${count.index}"].self_link
      device_name = attached_disk.value["device_name"]
    }
  }
}

locals {
  name_prefix = var.name_override == null ? "${var.prefix}-${var.node_type}" : var.name_override

  external_ips = length(var.external_ips) == 0 ? google_compute_address.gitlab[*].address : var.external_ips

  node_data_disks = flatten([
    for i in range(var.node_count) :
    [
      for data_disk in var.disks : {
        device_name = try(data_disk.name, data_disk.device_name)
        size        = lookup(data_disk, "size", var.disk_size)
        type        = lookup(data_disk, "type", var.disk_type)
        node_num    = i
        zone        = var.zones == null ? null : element(var.zones, i)
      }
    ]
  ])
}

## Service Account
resource "google_service_account" "gitlab" {
  count = min(var.node_count, 1)

  account_id   = "${var.service_account_prefix}-${var.node_type}"
  display_name = local.name_prefix
}

## Data Disks
resource "google_compute_disk" "gitlab" {
  for_each = { for d in local.node_data_disks : "${d.device_name}-${d.node_num}" => d }
  name     = "${local.name_prefix}-${each.value.device_name}-${each.value.node_num}"
  type     = each.value.type
  size     = each.value.size
  zone     = each.value.zone
}

## External IP
resource "google_compute_address" "gitlab" {
  count = length(var.external_ips) == 0 && var.setup_external_ip ? var.node_count : 0
  name  = "${local.name_prefix}-ip-${count.index + 1}"
}
