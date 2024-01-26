locals {
  total_node_pool_count = var.webservice_node_pool_count + var.sidekiq_node_pool_count + var.supporting_node_pool_count + var.webservice_node_pool_max_count + var.sidekiq_node_pool_max_count + var.supporting_node_pool_max_count

  node_pool_locations = var.gke_zones != null ? var.gke_zones : (var.kubernetes_zones != null ? var.kubernetes_zones : var.zones)
}

resource "google_container_cluster" "gitlab_cluster" {
  count = min(local.total_node_pool_count, 1)

  name     = var.prefix
  location = var.gke_location

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
  enable_shielded_nodes    = true

  deletion_protection = var.gke_deletion_protection

  network    = local.vpc_name
  subnetwork = local.subnet_name

  # Require VPC Native cluster
  # https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/using_gke_with_terraform#vpc-native-clusters
  # Blank block enables this and picks at random
  ip_allocation_policy {}

  release_channel {
    channel = var.cluster_release_channel != null ? var.cluster_release_channel : var.gke_release_channel
  }

  dynamic "private_cluster_config" {
    for_each = range(var.gke_enable_private_nodes ? 1 : 0)

    content {
      enable_private_nodes    = var.gke_enable_private_nodes
      enable_private_endpoint = var.gke_enable_private_endpoint # When false *both* Public and Private endpoints are enabled, this would be better named as enable_private_endpoint_only
      master_ipv4_cidr_block  = var.gke_master_ipv4_cidr_block
    }
  }

  # Limit GKE endpoint access via CIDR blocks for both Private and Public endpoints
  # This block being present alone with no settings will enable, which is required for Cluster's with private only endpoints (a CIDR block though is optional)
  dynamic "master_authorized_networks_config" {
    for_each = range(var.gke_enable_private_endpoint || length(var.gke_master_authorized_networks_config_cidr_blocks) > 0 ? 1 : 0)

    content {
      dynamic "cidr_blocks" {
        for_each = var.gke_master_authorized_networks_config_cidr_blocks

        content {
          cidr_block = cidr_blocks.value
        }
      }
    }
  }

  dynamic "workload_identity_config" {
    for_each = range(var.gke_enable_workload_identity || var.cluster_enable_workload_identity ? 1 : 0)

    content {
      workload_pool = "${var.project}.svc.id.goog"
    }
  }

  # Additional secrets envelope additional encryption - https://cloud.google.com/kubernetes-engine/docs/how-to/encrypting-secrets
  dynamic "database_encryption" {
    for_each = range(var.gke_database_encryption_key_name != null ? 1 : 0)

    content {
      state    = "ENCRYPTED"
      key_name = var.gke_database_encryption_key_name
    }
  }

  resource_labels = {
    gitlab_node_prefix = var.prefix
    gitlab_node_type   = "gitlab-cluster"
  }

  # Ensure avoidance of unexpected rebuilds as location controls Regional / Zonal clusters
  lifecycle {
    ignore_changes = [
      location
    ]
  }
}

resource "google_container_node_pool" "gitlab_webservice_pool" {
  count = min(var.webservice_node_pool_count + var.webservice_node_pool_max_count, 1)

  # Max 14 chars, unique_id adds 26 chars, total max 40.
  name_prefix    = "gl-webservice-"
  cluster        = google_container_cluster.gitlab_cluster[0].name
  node_locations = local.node_pool_locations

  # Node Count(s)
  # Total counts via Autoscaling ensure correct numbers cross zones - https://cloud.google.com/kubernetes-engine/docs/concepts/cluster-autoscaler#minimum_and_maximum_node_pool_size
  initial_node_count = var.webservice_node_pool_min_count > 0 ? var.webservice_node_pool_min_count : var.webservice_node_pool_count
  autoscaling {
    total_max_node_count = var.webservice_node_pool_max_count > 0 ? var.webservice_node_pool_max_count : var.webservice_node_pool_count
    total_min_node_count = var.webservice_node_pool_min_count > 0 ? var.webservice_node_pool_min_count : var.webservice_node_pool_count
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  upgrade_settings {
    max_surge       = 2
    max_unavailable = 0
  }

  node_config {
    machine_type = var.webservice_node_pool_machine_type
    disk_type    = coalesce(var.webservice_node_pool_disk_type, var.default_disk_type)
    disk_size_gb = coalesce(var.webservice_node_pool_disk_size, var.default_disk_size)

    service_account = google_service_account.gitlab_gke_webservice_service_account[0].email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"] # https://cloud.google.com/compute/docs/access/create-enable-service-accounts-for-instances#best_practices

    shielded_instance_config {
      enable_secure_boot = var.machine_secure_boot
    }

    dynamic "workload_metadata_config" {
      for_each = range(var.gke_enable_workload_identity || var.cluster_enable_workload_identity ? 1 : 0)

      content {
        mode = "GKE_METADATA"
      }
    }

    # Added by GCP, if not added here TF will recreate each time
    # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster#metadata
    metadata = {
      disable-legacy-endpoints = true
    }

    labels = {
      workload = "webservice"
    }

    resource_labels = {
      gitlab_node_prefix = var.prefix
      gitlab_node_type   = "gitlab-webservice-node-pool"
    }
  }

  lifecycle {
    ignore_changes = [
      initial_node_count,
    ]
  }
}

resource "google_container_node_pool" "gitlab_sidekiq_pool" {
  count = min(var.sidekiq_node_pool_count + var.sidekiq_node_pool_max_count, 1)

  # Max 14 chars, unique_id adds 26 chars, total max 40.
  name_prefix    = "gl-sidekiq-"
  cluster        = google_container_cluster.gitlab_cluster[0].name
  node_locations = local.node_pool_locations

  # Node Count(s)
  # Total counts via Autoscaling ensure correct numbers cross zones - https://cloud.google.com/kubernetes-engine/docs/concepts/cluster-autoscaler#minimum_and_maximum_node_pool_size
  initial_node_count = var.sidekiq_node_pool_min_count > 0 ? var.sidekiq_node_pool_min_count : var.sidekiq_node_pool_count
  autoscaling {
    total_max_node_count = var.sidekiq_node_pool_max_count > 0 ? var.sidekiq_node_pool_max_count : var.sidekiq_node_pool_count
    total_min_node_count = var.sidekiq_node_pool_min_count > 0 ? var.sidekiq_node_pool_min_count : var.sidekiq_node_pool_count
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  upgrade_settings {
    max_surge       = 2
    max_unavailable = 0
  }

  node_config {
    machine_type = var.sidekiq_node_pool_machine_type
    disk_type    = coalesce(var.sidekiq_node_pool_disk_type, var.default_disk_type)
    disk_size_gb = coalesce(var.sidekiq_node_pool_disk_size, var.default_disk_size)

    service_account = google_service_account.gitlab_gke_sidekiq_service_account[0].email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"] # https://cloud.google.com/compute/docs/access/create-enable-service-accounts-for-instances#best_practices

    shielded_instance_config {
      enable_secure_boot = var.machine_secure_boot
    }

    dynamic "workload_metadata_config" {
      for_each = range(var.gke_enable_workload_identity || var.cluster_enable_workload_identity ? 1 : 0)

      content {
        mode = "GKE_METADATA"
      }
    }

    # Added by GCP, if not added here TF will recreate each time
    # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster#metadata
    metadata = {
      disable-legacy-endpoints = true
    }

    labels = {
      workload = "sidekiq"
    }

    resource_labels = {
      gitlab_node_prefix = var.prefix
      gitlab_node_type   = "gitlab-sidekiq-node-pool"
    }
  }

  lifecycle {
    ignore_changes = [
      initial_node_count,
    ]
  }
}

resource "google_container_node_pool" "gitlab_supporting_pool" {
  count = min(var.supporting_node_pool_count + var.supporting_node_pool_max_count, 1)

  # Max 14 chars, unique_id adds 26 chars, total max 40.
  name_prefix    = "gl-supporting-"
  cluster        = google_container_cluster.gitlab_cluster[0].name
  node_locations = local.node_pool_locations

  # Node Count(s)
  # Total counts via Autoscaling ensure correct numbers cross zones - https://cloud.google.com/kubernetes-engine/docs/concepts/cluster-autoscaler#minimum_and_maximum_node_pool_size
  initial_node_count = var.supporting_node_pool_min_count > 0 ? var.supporting_node_pool_min_count : var.supporting_node_pool_count
  autoscaling {
    total_max_node_count = var.supporting_node_pool_max_count > 0 ? var.supporting_node_pool_max_count : var.supporting_node_pool_count
    total_min_node_count = var.supporting_node_pool_min_count > 0 ? var.supporting_node_pool_min_count : var.supporting_node_pool_count
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  upgrade_settings {
    max_surge       = 2
    max_unavailable = 0
  }

  node_config {
    machine_type = var.supporting_node_pool_machine_type
    disk_type    = coalesce(var.supporting_node_pool_disk_type, var.default_disk_type)
    disk_size_gb = coalesce(var.supporting_node_pool_disk_size, var.default_disk_size)

    service_account = google_service_account.gitlab_gke_supporting_service_account[0].email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"] # https://cloud.google.com/compute/docs/access/create-enable-service-accounts-for-instances#best_practices

    shielded_instance_config {
      enable_secure_boot = var.machine_secure_boot
    }

    dynamic "workload_metadata_config" {
      for_each = range(var.gke_enable_workload_identity || var.cluster_enable_workload_identity ? 1 : 0)

      content {
        mode = "GKE_METADATA"
      }
    }

    # Added by GCP, if not added here TF will recreate each time
    # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster#metadata
    metadata = {
      disable-legacy-endpoints = true
    }

    labels = {
      workload = "support"
    }

    resource_labels = {
      gitlab_node_prefix = var.prefix
      gitlab_node_type   = "gitlab-supporting-node-pool"
    }
  }

  lifecycle {
    ignore_changes = [
      initial_node_count,
    ]
  }
}

## Service Accounts
### Webservice
resource "google_service_account" "gitlab_gke_webservice_service_account" {
  count = min(var.webservice_node_pool_count + var.webservice_node_pool_max_count, 1)

  # Ensure account ID is 30 characters or less by trimming and only using alnum characters
  account_id   = "${var.service_account_prefix}-gke-webservice"
  display_name = "${var.prefix}-gke-webservice"
}

### Sidekiq
resource "google_service_account" "gitlab_gke_sidekiq_service_account" {
  count = min(var.sidekiq_node_pool_count + var.sidekiq_node_pool_max_count, 1)

  # Ensure account ID is 30 characters or less by trimming and only using alnum characters
  account_id   = "${var.service_account_prefix}-gke-sidekiq"
  display_name = "${var.prefix}-gke-sidekiq"
}

### Supporting
resource "google_service_account" "gitlab_gke_supporting_service_account" {
  count = min(var.supporting_node_pool_count + var.supporting_node_pool_max_count, 1)

  # Ensure account ID is 30 characters or less by trimming and only using alnum characters
  account_id   = "${var.service_account_prefix}-gke-supporting"
  display_name = "${var.prefix}-gke-supporting"
}

## Firewall
resource "google_compute_firewall" "gitlab_kubernetes_vms_internal" {
  name    = "${var.prefix}-kubernetes-vms-internal"
  network = local.vpc_name
  count   = min(local.total_node_pool_count, 1)

  description = "Allow internal access between GitLab Kubernetes containers and VMs"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
  }

  source_ranges = [google_container_cluster.gitlab_cluster[count.index].cluster_ipv4_cidr]
}

output "kubernetes" {
  value = {
    "kubernetes_cluster_name"    = try(google_container_cluster.gitlab_cluster[0].name, "")
    "kubernetes_cluster_version" = try(google_container_cluster.gitlab_cluster[0].master_version, "")

    # Service Accounts
    "kubernetes_webservice_node_group_service_account_email" = try(google_service_account.gitlab_gke_webservice_service_account[0].email, "")
    "kubernetes_sidekiq_node_group_service_account_email"    = try(google_service_account.gitlab_gke_sidekiq_service_account[0].email, "")
    "kubernetes_supporting_node_group_service_account_email" = try(google_service_account.gitlab_gke_supporting_service_account[0].email, "")

    # Node Group / Addon Versions
    "kubernetes_webservice_node_group_version" = try(google_container_node_pool.gitlab_webservice_pool[0].version, "")
    "kubernetes_sidekiq_node_group_version"    = try(google_container_node_pool.gitlab_sidekiq_pool[0].version, "")
    "kubernetes_supporting_node_group_version" = try(google_container_node_pool.gitlab_supporting_pool[0].version, "")
  }
}
