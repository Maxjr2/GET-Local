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
  member = "serviceAccount:${module.gitlab_rails.service_account.email}"
}
resource "google_storage_bucket_iam_member" "gitlab_sidekiq_object_storage_buckets_member" {
  for_each = var.sidekiq_node_count > 0 ? google_storage_bucket.gitlab_object_storage_buckets : tomap({})

  bucket = each.value.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${module.sidekiq.service_account.email}"
}

## Kubernetes
resource "google_storage_bucket_iam_member" "gitlab_gke_webservice_object_storage_buckets_member" {
  for_each = var.webservice_node_pool_count + var.webservice_node_pool_max_count > 0 ? google_storage_bucket.gitlab_object_storage_buckets : tomap({})

  bucket = each.value.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.gitlab_gke_webservice_service_account[0].email}"
}
resource "google_storage_bucket_iam_member" "gitlab_gke_sidekiq_object_storage_buckets_member" {
  for_each = var.sidekiq_node_pool_count + var.sidekiq_node_pool_max_count > 0 ? google_storage_bucket.gitlab_object_storage_buckets : tomap({})

  bucket = each.value.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.gitlab_gke_sidekiq_service_account[0].email}"
}
resource "google_storage_bucket_iam_member" "gitlab_gke_supporting_object_storage_buckets_member" {
  for_each = var.supporting_node_pool_count + var.supporting_node_pool_max_count > 0 ? google_storage_bucket.gitlab_object_storage_buckets : tomap({})

  bucket = each.value.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.gitlab_gke_supporting_service_account[0].email}"
}

# IAM Service Account Token role
## Required for signBlob permission, which is required Service Accounts to access storage via Application Default Credentials
## Role is strictly only given to the account directly to avoid impersonation attacks (https://docs.bridgecrew.io/docs/bc_gcp_iam_3)

## Omnibus
resource "google_service_account_iam_member" "gitlab_rails_service_account_token_role" {
  count = min(var.gitlab_rails_node_count, 1)

  service_account_id = module.gitlab_rails.service_account.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${module.gitlab_rails.service_account.email}"
}
resource "google_service_account_iam_member" "gitlab_sidekiq_service_account_token_role" {
  count = min(var.sidekiq_node_count, 1)

  service_account_id = module.sidekiq.service_account.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${module.sidekiq.service_account.email}"
}

## Kubernetes
resource "google_service_account_iam_member" "gitlab_gke_webservice_service_account_token_role" {
  count = min(var.webservice_node_pool_count + var.webservice_node_pool_max_count, 1)

  service_account_id = google_service_account.gitlab_gke_webservice_service_account[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.gitlab_gke_webservice_service_account[0].email}"
}
resource "google_service_account_iam_member" "gitlab_gke_sidekiq_service_account_token_role" {
  count = min(var.sidekiq_node_pool_count + var.sidekiq_node_pool_max_count, 1)

  service_account_id = google_service_account.gitlab_gke_sidekiq_service_account[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.gitlab_gke_sidekiq_service_account[0].email}"
}
resource "google_service_account_iam_member" "gitlab_gke_supporting_service_account_token_role" {
  count = min(var.supporting_node_pool_count + var.supporting_node_pool_max_count, 1)

  service_account_id = google_service_account.gitlab_gke_supporting_service_account[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.gitlab_gke_supporting_service_account[0].email}"
}
