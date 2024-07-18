locals {
  # https://docs.gitlab.com/ee/administration/troubleshooting/postgresql.html#database-deadlocks
  # statement_timeout setting not available on GCP Cloud SQL
  cloud_sql_praefect_postgres_default_params = { password_encryption = "scram-sha-256", log_min_duration_statement = 1000, idle_in_transaction_session_timeout = 60000, deadlock_timeout = 5000 }
  cloud_sql_praefect_postgres_ssl_mode       = var.cloud_sql_praefect_postgres_require_ssl ? "TRUSTED_CLIENT_CERTIFICATE_REQUIRED" : var.cloud_sql_praefect_postgres_ssl_mode
}

resource "google_sql_database_instance" "gitlab_praefect" {
  count = var.cloud_sql_praefect_postgres_machine_tier != "" ? 1 : 0

  name             = "${var.prefix}-praefect-cloud-sql"
  database_version = var.cloud_sql_praefect_postgres_version

  root_password = var.cloud_sql_praefect_postgres_root_password

  settings {
    tier    = "db-${var.cloud_sql_praefect_postgres_machine_tier}"
    edition = var.cloud_sql_praefect_postgres_edition

    disk_type = var.cloud_sql_praefect_postgres_disk_type
    disk_size = var.cloud_sql_praefect_postgres_disk_size

    availability_type = var.cloud_sql_praefect_postgres_availability_type

    ip_configuration {
      ipv4_enabled    = false
      private_network = local.create_network ? google_compute_network.gitlab_vpc[0].id : data.google_compute_network.gitlab_network.id
      ssl_mode        = local.cloud_sql_praefect_postgres_ssl_mode
      require_ssl     = local.cloud_sql_praefect_postgres_ssl_mode == "TRUSTED_CLIENT_CERTIFICATE_REQUIRED" ? true : null
    }

    dynamic "database_flags" {
      for_each = merge(local.cloud_sql_praefect_postgres_default_params, var.cloud_sql_praefect_postgres_params)
      content {
        name  = database_flags.key
        value = database_flags.value
      }
    }

    dynamic "backup_configuration" {
      for_each = range(var.cloud_sql_praefect_postgres_backup_configuration["enabled"] == true ? 1 : 0)

      content {
        enabled = var.cloud_sql_praefect_postgres_backup_configuration["enabled"]

        start_time = var.cloud_sql_praefect_postgres_backup_configuration["start_time"]

        location = var.cloud_sql_praefect_postgres_backup_configuration["location"]

        point_in_time_recovery_enabled = var.cloud_sql_praefect_postgres_backup_configuration["point_in_time_recovery_enabled"]
        transaction_log_retention_days = var.cloud_sql_praefect_postgres_backup_configuration["transaction_log_retention_days"]

        dynamic "backup_retention_settings" {
          for_each = range(var.cloud_sql_praefect_postgres_backup_configuration["retained_backups"] != null ? 1 : 0)

          content {
            retained_backups = var.cloud_sql_praefect_postgres_backup_configuration["retained_backups"]
          }
        }
      }
    }

    dynamic "maintenance_window" {
      for_each = range(var.cloud_sql_praefect_postgres_maintenance_window["day"] != null ? 1 : 0)

      content {
        day  = var.cloud_sql_praefect_postgres_maintenance_window["day"]
        hour = var.cloud_sql_praefect_postgres_maintenance_window["hour"]

        update_track = var.cloud_sql_praefect_postgres_maintenance_window["update_track"]
      }
    }

    user_labels = var.additional_labels
  }

  deletion_protection = var.cloud_sql_praefect_postgres_deletion_protection
  encryption_key_name = var.cloud_sql_praefect_postgres_encryption_key_name

  lifecycle {
    ignore_changes = [
      # Can only be set for new instances so ignore any subsequent changes
      encryption_key_name,
      settings[0].disk_type
    ]
  }

  depends_on = [
    google_service_networking_connection.gitlab_private_service_access[0]
  ]
}

output "cloud_sql_praefect_postgres_connection" {
  value = {
    "cloud_sql_host"    = try(google_sql_database_instance.gitlab_praefect[0].ip_address[0].ip_address, "")
    "cloud_sql_version" = try(google_sql_database_instance.gitlab_praefect[0].maintenance_version, "")
  }
}
