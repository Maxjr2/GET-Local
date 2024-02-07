# IAM Profiles - https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account_iam

# Service Account usage - serviceAccountUser
## Needed to grant permissions for users to in turn use that Service Account, i.e. Attach it to a VM.
## Role is strictly only given to the account running Terraform or a configured list to avoid impersonation attacks (https://docs.bridgecrew.io/docs/bc_gcp_iam_3)
data "google_client_openid_userinfo" "current_userinfo" {
  count = local.create_service_account ? 1 : 0
}

resource "google_service_account_iam_binding" "gitlab_user_members" {
  count = local.create_service_account ? 1 : 0

  service_account_id = google_service_account.gitlab[0].name
  role               = "roles/iam.serviceAccountUser"

  members = length(var.service_account_user_members) > 0 ? var.service_account_user_members : ["${strcontains(data.google_client_openid_userinfo.current_userinfo[0].email, "gserviceaccount") ? "serviceAccount" : "user"}:${data.google_client_openid_userinfo.current_userinfo[0].email}"]
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
