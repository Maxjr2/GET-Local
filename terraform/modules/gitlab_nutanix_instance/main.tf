terraform {
  required_version = ">= 1.12"

  required_providers {
    nutanix = {
      source  = "nutanix/nutanix"
      version = "~> 2.4"
    }
  }
}

locals {
  node_categories = {
    for i in range(var.node_count) : i => merge({
      gitlab_node_prefix    = var.prefix
      gitlab_node_type      = var.node_type
      gitlab_node_level     = var.label_secondaries ? (i == 0 ? "${var.node_type}-primary" : "${var.node_type}-secondary") : null
      gitlab_geo_site       = var.geo_site
      gitlab_geo_deployment = var.geo_deployment
    }, var.custom_categories)
  }
}

resource "nutanix_virtual_machine" "gitlab" {
  count        = var.node_count
  name         = "${var.prefix}-${var.node_type}-${count.index + 1}"
  cluster_uuid = var.cluster_uuid

  num_sockets          = var.size.num_sockets
  num_vcpus_per_socket = var.size.num_vcpus_per_socket
  memory_size_mib      = var.size.memory_size_mib

  disk_list {
    data_source_reference = {
      kind = "image"
      uuid = var.image_uuid
    }
    disk_size_mib = tonumber(var.disk_size) * 1024
  }

  dynamic "disk_list" {
    for_each = var.data_disks
    content {
      disk_size_mib = tonumber(coalesce(disk_list.value.size, var.disk_size)) * 1024
      storage_config {
        storage_container_reference {
          kind = "storage_container"
          uuid = coalesce(disk_list.value.storage_container_uuid, var.storage_container_uuid)
        }
      }
    }
  }

  nic_list {
    subnet_uuid = var.subnet_uuid
  }

  guest_customization_cloud_init_user_data = base64encode(templatefile("${path.module}/templates/cloud_init.yaml.tpl", {
    hostname = "${var.prefix}-${var.node_type}-${count.index + 1}"
    username = var.vm_admin_username
    ssh_key  = var.ssh_public_key
  }))

  dynamic "categories" {
    for_each = { for k, v in local.node_categories[count.index] : k => v if v != null }
    content {
      name  = categories.key
      value = categories.value
    }
  }

  lifecycle {
    ignore_changes = [
      disk_list[0].data_source_reference, # Prevents forced replacement when a newer image version is published; image updates are handled separately
    ]
  }
}
