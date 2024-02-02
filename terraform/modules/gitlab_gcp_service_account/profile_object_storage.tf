# This file contains IAM definitions for services accounts with required access `self_token_creator`
locals {
  add_object_storage_profile_memberships = local.create_service_account && contains(var.service_account_profiles, "object_storage")
}

# IAM Service Account Token role
# Required for signBlob permission, which is required Service Accounts to access storage via Application Default Credentials
# https://cloud.google.com/iam/docs/reference/credentials/rest/v1/projects.serviceAccounts/signBlob
#
# Role is strictly only given to the account directly to avoid impersonation attacks (https://docs.bridgecrew.io/docs/bc_gcp_iam_3)
resource "google_service_account_iam_member" "object_storage_profile_token_creator" {
  count = local.add_object_storage_profile_memberships ? 1 : 0

  service_account_id = google_service_account.gitlab[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = google_service_account.gitlab[0].member
}
