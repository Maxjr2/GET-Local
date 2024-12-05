module "postgres" {
  source = "../gitlab_gcp_instance"

  prefix     = var.prefix
  node_type  = "postgres"
  node_count = var.postgres_node_count
  # TODO: var.additional_labels is deprecated and will be removed in 4.x
  custom_labels = merge(var.additional_labels, var.custom_labels, var.postgres_custom_labels)

  machine_type  = var.postgres_machine_type
  machine_image = var.machine_image

  disk_size    = coalesce(var.postgres_disk_size, var.default_disk_size)
  disk_type    = coalesce(var.postgres_disk_type, var.default_disk_type)
  disk_kms_key = var.postgres_disk_kms_key != null ? var.postgres_disk_kms_key : var.default_disk_kms_key
  disks        = var.postgres_disks

  vpc               = local.create_network ? google_compute_network.gitlab_vpc[0].self_link : data.google_compute_network.gitlab_network[0].self_link
  subnet            = local.create_network ? google_compute_subnetwork.gitlab_vpc_subnet[0].self_link : data.google_compute_subnetwork.gitlab_subnet[0].self_link
  zones             = var.zones
  setup_external_ip = var.setup_external_ips

  service_account_prefix       = var.service_account_prefix
  service_account_user_members = var.service_account_user_members
  custom_service_account_email = lookup(var.custom_service_account_emails, "postgres", null)

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment

  label_secondaries = true

  allow_stopping_for_update = var.allow_stopping_for_update
  machine_secure_boot       = var.machine_secure_boot
}

output "postgres" {
  value = module.postgres
}
