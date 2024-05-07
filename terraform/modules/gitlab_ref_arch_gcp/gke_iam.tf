## Service Account
### Webservice (Node or Workload Identity ADC)
module "gitlab_gke_webservice_service_account" {
  count  = var.webservice_node_pool_count + var.webservice_node_pool_max_count > 0 ? 1 : 0
  source = "../gitlab_gcp_service_account"

  # Ensure account ID is 30 characters or less by trimming and only using alnum characters
  account_id   = "${var.service_account_prefix}-gke-webservice"
  display_name = "${var.prefix}-gke-webservice"

  service_account_profiles     = ["object_storage"]
  service_account_user_members = var.service_account_user_members
  custom_service_account_email = lookup(var.custom_service_account_emails, "gke-webservice", null)

  # Set Workload Identity role if using
  service_account_workload_identity_member = var.gke_enable_workload_identity ? "serviceAccount:${var.project}.svc.id.goog[${var.gke_gitlab_charts_namespace}/gitlab-webservice]" : null
}
### Sidekiq (Node or Workload Identity ADC)
module "gitlab_gke_sidekiq_service_account" {
  count  = var.sidekiq_node_pool_count + var.sidekiq_node_pool_max_count > 0 ? 1 : 0
  source = "../gitlab_gcp_service_account"

  # Ensure account ID is 30 characters or less by trimming and only using alnum characters
  account_id   = "${var.service_account_prefix}-gke-sidekiq"
  display_name = "${var.prefix}-gke-sidekiq"

  service_account_profiles     = ["object_storage"]
  service_account_user_members = var.service_account_user_members
  custom_service_account_email = lookup(var.custom_service_account_emails, "gke-sidekiq", null)

  # Set Workload Identity role if using
  service_account_workload_identity_member = var.gke_enable_workload_identity ? "serviceAccount:${var.project}.svc.id.goog[${var.gke_gitlab_charts_namespace}/gitlab-sidekiq]" : null
}

### Supporting (Node ADC)
module "gitlab_gke_supporting_service_account" {
  count  = var.supporting_node_pool_count + var.supporting_node_pool_max_count > 0 && !var.gke_enable_workload_identity ? 1 : 0
  source = "../gitlab_gcp_service_account"

  # Ensure account ID is 30 characters or less by trimming and only using alnum characters
  account_id   = "${var.service_account_prefix}-gke-supporting"
  display_name = "${var.prefix}-gke-supporting"

  service_account_profiles     = ["object_storage"]
  service_account_user_members = var.service_account_user_members
  custom_service_account_email = lookup(var.custom_service_account_emails, "gke-supporting", null)
}

### Node (Workload Identity ADC)
module "gitlab_gke_node_service_account" {
  count  = local.total_node_pool_count > 0 && var.gke_enable_workload_identity ? 1 : 0
  source = "../gitlab_gcp_service_account"

  # Ensure account ID is 30 characters or less by trimming and only using alnum characters
  account_id   = "${var.service_account_prefix}-gke-node"
  display_name = "${var.prefix}-gke-node"

  service_account_user_members = var.service_account_user_members
  custom_service_account_email = lookup(var.custom_service_account_emails, "gke-node", null)
}
### Toolbox (Workload Identity ADC)
module "gitlab_gke_toolbox_service_account" {
  count  = var.supporting_node_pool_count + var.supporting_node_pool_max_count > 0 && var.gke_enable_workload_identity ? 1 : 0
  source = "../gitlab_gcp_service_account"

  # Ensure account ID is 30 characters or less by trimming and only using alnum characters
  account_id   = "${var.service_account_prefix}-gke-toolbox"
  display_name = "${var.prefix}-gke-toolbox"

  service_account_profiles     = ["object_storage"]
  service_account_user_members = var.service_account_user_members
  custom_service_account_email = lookup(var.custom_service_account_emails, "gke-toolbox", null)

  # Set Workload Identity role
  service_account_workload_identity_member = "serviceAccount:${var.project}.svc.id.goog[${var.gke_gitlab_charts_namespace}/gitlab-toolbox]"
}
### Registry (Workload Identity ADC)
module "gitlab_gke_registry_service_account" {
  count  = var.supporting_node_pool_count + var.supporting_node_pool_max_count > 0 && var.gke_enable_workload_identity ? 1 : 0
  source = "../gitlab_gcp_service_account"

  # Ensure account ID is 30 characters or less by trimming and only using alnum characters
  account_id   = "${var.service_account_prefix}-gke-registry"
  display_name = "${var.prefix}-gke-registry"

  service_account_profiles     = ["object_storage"]
  service_account_user_members = var.service_account_user_members
  custom_service_account_email = lookup(var.custom_service_account_emails, "gke-registry", null)

  # Set Workload Identity role
  service_account_workload_identity_member = "serviceAccount:${var.project}.svc.id.goog[${var.gke_gitlab_charts_namespace}/gitlab-registry]"
}

## Refactors
moved {
  from = google_service_account.gitlab_gke_webservice_service_account
  to   = module.gitlab_gke_webservice_service_account[0].google_service_account.gitlab
}
moved {
  from = google_service_account.gitlab_gke_sidekiq_service_account
  to   = module.gitlab_gke_sidekiq_service_account[0].google_service_account.gitlab
}
moved {
  from = google_service_account.gitlab_gke_supporting_service_account
  to   = module.gitlab_gke_supporting_service_account[0].google_service_account.gitlab
}
