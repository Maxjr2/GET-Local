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
resource "google_storage_bucket_iam_member" "gitlab_gke_webservice_object_storage_buckets_member" {
  for_each = var.webservice_node_pool_count + var.webservice_node_pool_max_count > 0 ? google_storage_bucket.gitlab_object_storage_buckets : tomap({})

  bucket = each.value.name
  role   = "roles/storage.objectAdmin"
  member = module.gitlab_gke_webservice_service_account[0].member
}
resource "google_storage_bucket_iam_member" "gitlab_gke_sidekiq_object_storage_buckets_member" {
  for_each = var.sidekiq_node_pool_count + var.sidekiq_node_pool_max_count > 0 ? google_storage_bucket.gitlab_object_storage_buckets : tomap({})

  bucket = each.value.name
  role   = "roles/storage.objectAdmin"
  member = module.gitlab_gke_sidekiq_service_account[0].member
}
resource "google_storage_bucket_iam_member" "gitlab_gke_supporting_object_storage_buckets_member" {
  for_each = var.supporting_node_pool_count + var.supporting_node_pool_max_count > 0 ? google_storage_bucket.gitlab_object_storage_buckets : tomap({})

  bucket = each.value.name
  role   = "roles/storage.objectAdmin"
  member = module.gitlab_gke_supporting_service_account[0].member
}

### Geo Replication Kubernetes
locals {
  create_geo_primary_site_iam   = var.geo_primary_site_object_storage_prefix != null
  geo_primary_site_bucket_names = local.create_geo_primary_site_iam ? [for b in coalescelist(var.geo_primary_site_object_storage_buckets, var.object_storage_buckets) : "${var.geo_primary_site_object_storage_prefix}-${b}"] : null
}

resource "google_storage_bucket_iam_member" "geo_primary_gitlab_gke_supporting_object_storage_buckets_member" {
  for_each = local.create_geo_primary_site_iam && (var.supporting_node_pool_count + var.supporting_node_pool_max_count > 0) ? toset(local.geo_primary_site_bucket_names) : toset([])

  bucket = each.value
  role   = "roles/storage.objectAdmin"
  member = module.gitlab_gke_supporting_service_account[0].member
}
