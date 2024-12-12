module "gitlab_rails" {
  source = "../gitlab_gcp_instance"

  prefix     = var.prefix
  node_type  = "gitlab-rails"
  node_count = var.gitlab_rails_node_count
  # TODO: var.additional_labels is deprecated and will be removed in 4.x
  custom_labels   = merge(var.additional_labels, var.custom_labels, var.gitlab_rails_custom_labels)
  custom_metadata = merge(var.custom_metadata, var.gitlab_rails_custom_metadata)

  machine_type  = var.gitlab_rails_machine_type
  machine_image = var.machine_image

  disk_size    = coalesce(var.gitlab_rails_disk_size, var.default_disk_size)
  disk_type    = coalesce(var.gitlab_rails_disk_type, var.default_disk_type)
  disk_kms_key = var.gitlab_rails_disk_kms_key != null ? var.gitlab_rails_disk_kms_key : var.default_disk_kms_key
  disks        = var.gitlab_rails_disks

  vpc               = local.create_network ? google_compute_network.gitlab_vpc[0].self_link : data.google_compute_network.gitlab_network[0].self_link
  subnet            = local.create_network ? google_compute_subnetwork.gitlab_vpc_subnet[0].self_link : data.google_compute_subnetwork.gitlab_subnet[0].self_link
  zones             = var.zones
  setup_external_ip = var.setup_external_ips
  external_ips      = var.gitlab_rails_external_ips

  service_account_prefix       = var.service_account_prefix
  service_account_user_members = var.service_account_user_members
  service_account_profiles     = ["object_storage"]
  custom_service_account_email = lookup(var.custom_service_account_emails, "gitlab-rails", null)

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment

  label_secondaries = true

  tags = length(var.gitlab_rails_external_ips) > 0 && var.haproxy_external_node_count == 0 ? ["${var.prefix}-web", "${var.prefix}-ssh"] : []

  allow_stopping_for_update = var.allow_stopping_for_update
  machine_secure_boot       = var.machine_secure_boot
}

output "gitlab_rails" {
  value = module.gitlab_rails
}
