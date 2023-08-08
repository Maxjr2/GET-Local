resource "google_redis_instance" "gitlab_redis" {
  count = var.memorystore_redis_node_count > 0 ? 1 : 0

  name           = "${format("%.34s", var.prefix)}-redis" # Must be 40 characters or lower
  display_name   = "${var.prefix}-redis"
  tier           = var.memorystore_redis_node_count > 1 ? "STANDARD_HA" : "BASIC"
  memory_size_gb = var.memorystore_redis_memory_size_gb

  auth_enabled            = true
  transit_encryption_mode = var.memorystore_redis_transit_encryption_mode
  authorized_network      = local.create_network ? google_compute_network.gitlab_vpc[0].id : data.google_compute_network.gitlab_network.id

  redis_version      = var.memorystore_redis_version
  replica_count      = var.memorystore_redis_node_count > 1 ? var.memorystore_redis_node_count : null
  read_replicas_mode = var.memorystore_redis_node_count > 1 ? "READ_REPLICAS_ENABLED" : "READ_REPLICAS_DISABLED"

  labels = var.additional_labels

  dynamic "maintenance_policy" {
    for_each = range(var.memorystore_redis_weekly_maintenance_window_day != null ? 1 : 0)

    content {
      weekly_maintenance_window {
        day = var.memorystore_redis_weekly_maintenance_window_day
        dynamic "start_time" {
          for_each = var.memorystore_redis_weekly_maintenance_window_start_time

          content {
            hours   = start_time.value["hours"]
            minutes = start_time.value["minutes"]
            seconds = start_time.value["seconds"]
            nanos   = start_time.value["nanos"]
          }
        }
      }
    }
  }
}

output "memorystore_redis_connection" {
  value = {
    "memorystore_redis_address" = try(google_redis_instance.gitlab_redis[0].host, "")
    "memorystore_redis_port"    = try(google_redis_instance.gitlab_redis[0].port, "")
  }
}

locals {
  ## Use default values if specifics aren't specfied
  memorystore_redis_cache_version                              = coalesce(var.memorystore_redis_cache_version, var.memorystore_redis_version)
  memorystore_redis_cache_transit_encryption_mode              = coalesce(var.memorystore_redis_cache_transit_encryption_mode, var.memorystore_redis_transit_encryption_mode)
  memorystore_redis_cache_weekly_maintenance_window_day        = var.memorystore_redis_cache_weekly_maintenance_window_day != null ? var.memorystore_redis_cache_weekly_maintenance_window_day : var.memorystore_redis_weekly_maintenance_window_day
  memorystore_redis_cache_weekly_maintenance_window_start_time = var.memorystore_redis_cache_weekly_maintenance_window_start_time != null ? var.memorystore_redis_cache_weekly_maintenance_window_start_time : var.memorystore_redis_weekly_maintenance_window_start_time
}

resource "google_redis_instance" "gitlab_redis_cache" {
  count = var.memorystore_redis_cache_node_count > 0 ? 1 : 0

  name           = "${format("%.28s", var.prefix)}-redis-cache" # Must be 40 characters or lower
  display_name   = "${var.prefix}-redis-cache"
  tier           = var.memorystore_redis_cache_node_count > 1 ? "STANDARD_HA" : "BASIC"
  memory_size_gb = var.memorystore_redis_cache_memory_size_gb

  auth_enabled            = true
  transit_encryption_mode = local.memorystore_redis_cache_transit_encryption_mode
  authorized_network      = local.create_network ? google_compute_network.gitlab_vpc[0].id : data.google_compute_network.gitlab_network.id

  redis_version      = local.memorystore_redis_cache_version
  replica_count      = var.memorystore_redis_cache_node_count > 1 ? var.memorystore_redis_cache_node_count : null
  read_replicas_mode = var.memorystore_redis_cache_node_count > 1 ? "READ_REPLICAS_ENABLED" : "READ_REPLICAS_DISABLED"

  redis_configs = {
    maxmemory-policy = "allkeys-lru"
  }

  labels = var.additional_labels

  dynamic "maintenance_policy" {
    for_each = range(local.memorystore_redis_cache_weekly_maintenance_window_day != null ? 1 : 0)

    content {
      weekly_maintenance_window {
        day = local.memorystore_redis_cache_weekly_maintenance_window_day

        dynamic "start_time" {
          for_each = local.memorystore_redis_cache_weekly_maintenance_window_start_time

          content {
            hours   = start_time.value["hours"]
            minutes = start_time.value["minutes"]
            seconds = start_time.value["seconds"]
            nanos   = start_time.value["nanos"]
          }
        }
      }
    }
  }
}

output "memorystore_redis_cache_connection" {
  value = {
    "memorystore_redis_cache_address" = try(google_redis_instance.gitlab_redis_cache[0].host, "")
    "memorystore_redis_cache_port"    = try(google_redis_instance.gitlab_redis_cache[0].port, "")
  }
}

locals {
  ## Use default values if specifics aren't specfied
  memorystore_redis_persistent_version                              = coalesce(var.memorystore_redis_persistent_version, var.memorystore_redis_version)
  memorystore_redis_persistent_transit_encryption_mode              = coalesce(var.memorystore_redis_persistent_transit_encryption_mode, var.memorystore_redis_transit_encryption_mode)
  memorystore_redis_persistent_weekly_maintenance_window_day        = var.memorystore_redis_persistent_weekly_maintenance_window_day != null ? var.memorystore_redis_persistent_weekly_maintenance_window_day : var.memorystore_redis_weekly_maintenance_window_day
  memorystore_redis_persistent_weekly_maintenance_window_start_time = var.memorystore_redis_persistent_weekly_maintenance_window_start_time != null ? var.memorystore_redis_persistent_weekly_maintenance_window_start_time : var.memorystore_redis_weekly_maintenance_window_start_time
}

resource "google_redis_instance" "gitlab_redis_persistent" {
  count = var.memorystore_redis_persistent_node_count > 0 ? 1 : 0

  name           = "${format("%.23s", var.prefix)}-redis-persistent" # Must be 40 characters or lower
  display_name   = "${var.prefix}-redis-persistent"
  tier           = var.memorystore_redis_persistent_node_count > 1 ? "STANDARD_HA" : "BASIC"
  memory_size_gb = var.memorystore_redis_persistent_memory_size_gb

  auth_enabled            = true
  transit_encryption_mode = local.memorystore_redis_persistent_transit_encryption_mode
  authorized_network      = local.create_network ? google_compute_network.gitlab_vpc[0].id : data.google_compute_network.gitlab_network.id

  redis_version      = local.memorystore_redis_persistent_version
  replica_count      = var.memorystore_redis_persistent_node_count > 1 ? var.memorystore_redis_persistent_node_count : null
  read_replicas_mode = var.memorystore_redis_persistent_node_count > 1 ? "READ_REPLICAS_ENABLED" : "READ_REPLICAS_DISABLED"

  labels = var.additional_labels

  dynamic "maintenance_policy" {
    for_each = range(local.memorystore_redis_persistent_weekly_maintenance_window_day != null ? 1 : 0)

    content {
      weekly_maintenance_window {
        day = local.memorystore_redis_persistent_weekly_maintenance_window_day
        dynamic "start_time" {
          for_each = local.memorystore_redis_persistent_weekly_maintenance_window_start_time

          content {
            hours   = start_time.value["hours"]
            minutes = start_time.value["minutes"]
            seconds = start_time.value["seconds"]
            nanos   = start_time.value["nanos"]
          }
        }
      }
    }
  }
}

output "memorystore_redis_persistent_connection" {
  value = {
    "memorystore_redis_persistent_address" = try(google_redis_instance.gitlab_redis_persistent[0].host, "")
    "memorystore_redis_persistent_port"    = try(google_redis_instance.gitlab_redis_persistent[0].port, "")
  }
}
