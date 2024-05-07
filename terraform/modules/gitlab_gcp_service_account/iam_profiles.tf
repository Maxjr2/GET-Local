# IAM Profiles - https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account_iam

# Service Account usage - serviceAccountUser
## Needed to grant permissions for users to in turn use that Service Account, i.e. Attach it to a VM or to allow SSH OS Login
## Role is strictly only given to the member accounts passed via service_account_user_members if given to avoid impersonation attacks (https://docs.bridgecrew.io/docs/bc_gcp_iam_3)
resource "google_service_account_iam_member" "gitlab_user_members" {
  for_each = local.create_service_account ? toset(var.service_account_user_members) : toset([])

  service_account_id = google_service_account.gitlab[0].name
  role               = "roles/iam.serviceAccountUser"
  member             = each.value
}

# Object Storage - serviceAccountTokenCreator
## Required for the signBlob permission, which is required by GitLab to access Object Storage with the Service Account via Application Default Credentials - https://docs.gitlab.com/ee/administration/object_storage.html#gcs-example-with-adc
## Role is strictly only given to the account directly to avoid impersonation attacks (https://docs.bridgecrew.io/docs/bc_gcp_iam_3)
resource "google_service_account_iam_member" "object_storage_profile_token_creator" {
  count = local.create_service_account && contains(var.service_account_profiles, "object_storage") ? 1 : 0

  service_account_id = google_service_account.gitlab[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = google_service_account.gitlab[0].member
}

# GKE Workload Identity - workloadIdentityUser
resource "google_service_account_iam_member" "workload_identity_member" {
  count = local.create_service_account && var.service_account_workload_identity_member != null ? 1 : 0

  service_account_id = google_service_account.gitlab[0].name
  role               = "roles/iam.workloadIdentityUser"
  member             = var.service_account_workload_identity_member
}
