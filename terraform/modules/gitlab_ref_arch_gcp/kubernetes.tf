locals {
  total_node_pool_count = var.webservice_node_pool_count + var.sidekiq_node_pool_count + var.supporting_node_pool_count + var.webservice_node_pool_max_count + var.sidekiq_node_pool_max_count + var.supporting_node_pool_max_count

  webservice_node_pool_autoscaling = var.webservice_node_pool_max_count > 0
  sidekiq_node_pool_autoscaling    = var.sidekiq_node_pool_max_count > 0
  supporting_node_pool_autoscaling = var.supporting_node_pool_max_count > 0

  node_pool_zones       = var.kubernetes_zones != null ? var.kubernetes_zones : var.zones
  node_pool_zones_count = local.node_pool_zones != null ? length(local.node_pool_zones) : 1
}

resource "google_container_cluster" "gitlab_cluster" {
  count = min(local.total_node_pool_count, 1)
  name  = var.prefix

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
  enable_shielded_nodes    = true

  network    = local.vpc_name
  subnetwork = local.subnet_name

  # Require VPC Native cluster
  # https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/using_gke_with_terraform#vpc-native-clusters
  # Blank block enables this and picks at random
  ip_allocation_policy {}

  release_channel {
    channel = var.cluster_release_channel
  }

  resource_labels = {
    gitlab_node_prefix = var.prefix
    gitlab_node_type   = "gitlab-cluster"
  }

  dynamic "workload_identity_config" {
    for_each = range(var.cluster_enable_workload_identity ? 1 : 0)

    content {
      workload_pool = "${var.project}.svc.id.goog"
    }
  }
}

resource "google_container_node_pool" "gitlab_webservice_pool" {
  count = min(var.webservice_node_pool_count + var.webservice_node_pool_max_count, 1)

  # Max 14 chars, unique_id adds 26 chars, total max 40.
  name_prefix    = "gl-webservice-"
  cluster        = google_container_cluster.gitlab_cluster[0].name
  node_locations = local.node_pool_zones

  node_count = local.webservice_node_pool_autoscaling ? null : ceil(var.webservice_node_pool_count / local.node_pool_zones_count)

  # Cluster Autoscaling (Optional)
  initial_node_count = local.webservice_node_pool_autoscaling ? ceil(var.webservice_node_pool_min_count / local.node_pool_zones_count) : null
  dynamic "autoscaling" {
    for_each = range(local.webservice_node_pool_autoscaling ? 1 : 0)

    content {
      max_node_count = ceil(var.webservice_node_pool_max_count / local.node_pool_zones_count)
      min_node_count = ceil(var.webservice_node_pool_min_count / local.node_pool_zones_count)
    }
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
      for_each = range(var.cluster_enable_workload_identity ? 1 : 0)

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
  node_locations = local.node_pool_zones

  node_count = local.sidekiq_node_pool_autoscaling ? null : ceil(var.sidekiq_node_pool_count / local.node_pool_zones_count)

  # Cluster Autoscaling (Optional)
  initial_node_count = local.sidekiq_node_pool_autoscaling ? ceil(var.sidekiq_node_pool_min_count / local.node_pool_zones_count) : null
  dynamic "autoscaling" {
    for_each = range(local.sidekiq_node_pool_autoscaling ? 1 : 0)

    content {
      max_node_count = ceil(var.sidekiq_node_pool_max_count / local.node_pool_zones_count)
      min_node_count = ceil(var.sidekiq_node_pool_min_count / local.node_pool_zones_count)
    }
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
      for_each = range(var.cluster_enable_workload_identity ? 1 : 0)

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
  node_locations = local.node_pool_zones

  node_count = local.supporting_node_pool_autoscaling ? null : ceil(var.supporting_node_pool_count / local.node_pool_zones_count)

  # Cluster Autoscaling (Optional)
  initial_node_count = local.supporting_node_pool_autoscaling ? ceil(var.supporting_node_pool_min_count / local.node_pool_zones_count) : null
  dynamic "autoscaling" {
    for_each = range(local.supporting_node_pool_autoscaling ? 1 : 0)

    content {
      max_node_count = ceil(var.supporting_node_pool_max_count / local.node_pool_zones_count)
      min_node_count = ceil(var.supporting_node_pool_min_count / local.node_pool_zones_count)
    }
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
      for_each = range(var.cluster_enable_workload_identity ? 1 : 0)

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
