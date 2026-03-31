module "praefect" {
  source = "../gitlab_gcp_instance"

  prefix     = var.prefix
  node_type  = "praefect"
  node_count = var.praefect_node_count
  # Deprecated: var.additional_labels is superseded by var.custom_labels.
  custom_labels   = merge(var.additional_labels, var.custom_labels, var.praefect_custom_labels)
  custom_metadata = merge(var.custom_metadata, var.praefect_custom_metadata)

  machine_type  = var.praefect_machine_type
  machine_image = var.machine_image

  disk_size    = coalesce(var.praefect_disk_size, var.default_disk_size)
  disk_type    = coalesce(var.praefect_disk_type, var.default_disk_type)
  disk_kms_key = var.praefect_disk_kms_key != null ? var.praefect_disk_kms_key : var.default_disk_kms_key
  disks        = var.praefect_disks

  vpc               = local.create_network ? google_compute_network.gitlab_vpc[0].self_link : data.google_compute_network.gitlab_network[0].self_link
  subnet            = local.create_network ? google_compute_subnetwork.gitlab_vpc_subnet[0].self_link : data.google_compute_subnetwork.gitlab_subnet[0].self_link
  zones             = var.zones
  setup_external_ip = var.setup_external_ips

  service_account_prefix       = var.service_account_prefix
  service_account_user_members = var.service_account_user_members
  custom_service_account_email = lookup(var.custom_service_account_emails, "praefect", null)

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment

  label_secondaries = true

  tags = var.setup_iap_ssh_access ? ["${var.prefix}-iap"] : []

  allow_stopping_for_update = var.allow_stopping_for_update
  machine_secure_boot       = var.machine_secure_boot
}

output "praefect" {
  value = module.praefect
}
