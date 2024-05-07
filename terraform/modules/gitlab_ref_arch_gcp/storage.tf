resource "google_storage_bucket" "gitlab_object_storage_buckets" {
  for_each = toset(var.object_storage_buckets)

  name          = "${var.object_storage_prefix != null ? var.object_storage_prefix : var.prefix}-${each.value}"
  location      = var.object_storage_location
  force_destroy = var.object_storage_force_destroy

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = var.object_storage_versioning
  }

  labels = var.object_storage_labels
}

# IAM Storage Admin Role
## Omnibus
resource "google_storage_bucket_iam_member" "gitlab_rails_object_storage_buckets_member" {
  for_each = var.gitlab_rails_node_count > 0 ? google_storage_bucket.gitlab_object_storage_buckets : tomap({})

  bucket = each.value.name
  role   = "roles/storage.objectAdmin"
  member = module.gitlab_rails.service_account.member
}
resource "google_storage_bucket_iam_member" "gitlab_sidekiq_object_storage_buckets_member" {
  for_each = var.sidekiq_node_count > 0 ? google_storage_bucket.gitlab_object_storage_buckets : tomap({})

  bucket = each.value.name
  role   = "roles/storage.objectAdmin"
  member = module.sidekiq.service_account.member
}

## Kubernetes
### Webservice (Node or Workload Identity ADC) - All Buckets except Backup & Registry
resource "google_storage_bucket_iam_member" "gitlab_gke_webservice_object_storage_buckets_member" {
  for_each = var.webservice_node_pool_count + var.webservice_node_pool_max_count > 0 ? { for k, v in google_storage_bucket.gitlab_object_storage_buckets : k => v if !contains(["registry", "backups"], k) } : tomap({})

  bucket = each.value.name
  role   = "roles/storage.objectAdmin"
  member = module.gitlab_gke_webservice_service_account[0].member
}
### Sidekiq (Node or Workload Identity ADC) - All Buckets except Backup & Registry
resource "google_storage_bucket_iam_member" "gitlab_gke_sidekiq_object_storage_buckets_member" {
  for_each = var.sidekiq_node_pool_count + var.sidekiq_node_pool_max_count > 0 ? { for k, v in google_storage_bucket.gitlab_object_storage_buckets : k => v if !contains(["registry", "backups"], k) } : tomap({})

  bucket = each.value.name
  role   = "roles/storage.objectAdmin"
  member = module.gitlab_gke_sidekiq_service_account[0].member
}

### Supporting (Node ADC) - All Buckets for Backup & Registry
resource "google_storage_bucket_iam_member" "gitlab_gke_supporting_object_storage_buckets_member" {
  for_each = var.supporting_node_pool_count + var.supporting_node_pool_max_count > 0 && !var.gke_enable_workload_identity ? google_storage_bucket.gitlab_object_storage_buckets : tomap({})

  bucket = each.value.name
  role   = "roles/storage.objectAdmin"
  member = module.gitlab_gke_supporting_service_account[0].member
}

### Toolbox (Workload Identity ADC) - All Buckets for Backup
resource "google_storage_bucket_iam_member" "gitlab_gke_toolbox_object_storage_buckets_member" {
  for_each = var.supporting_node_pool_count + var.supporting_node_pool_max_count > 0 && var.gke_enable_workload_identity ? google_storage_bucket.gitlab_object_storage_buckets : tomap({})

  bucket = each.value.name
  role   = "roles/storage.objectAdmin"
  member = module.gitlab_gke_toolbox_service_account[0].member
}
### Registry (Workload Identity ADC) - Registry Bucket
resource "google_storage_bucket_iam_member" "gitlab_gke_registry_object_storage_buckets_member" {
  count = var.gke_enable_workload_identity && length(var.object_storage_buckets) > 0 && contains(var.object_storage_buckets, "registry") && var.supporting_node_pool_count + var.supporting_node_pool_max_count > 0 ? 1 : 0

  bucket = google_storage_bucket.gitlab_object_storage_buckets["registry"].name
  role   = "roles/storage.objectAdmin"
  member = module.gitlab_gke_registry_service_account[0].member
}
