module "haproxy_external" {
  source = "../gitlab_gcp_instance"

  prefix     = var.prefix
  node_type  = "haproxy-external"
  node_count = var.haproxy_external_node_count
  # TODO: var.additional_labels is deprecated and will be removed in 4.x
  custom_labels = merge(var.additional_labels, var.custom_labels, var.haproxy_external_custom_labels)

  machine_type  = var.haproxy_external_machine_type
  machine_image = var.machine_image

  disk_size    = coalesce(var.haproxy_external_disk_size, var.default_disk_size)
  disk_type    = coalesce(var.haproxy_external_disk_type, var.default_disk_type)
  disk_kms_key = var.haproxy_external_disk_kms_key != null ? var.haproxy_external_disk_kms_key : var.default_disk_kms_key
  disks        = var.haproxy_external_disks

  vpc               = local.create_network ? google_compute_network.gitlab_vpc[0].self_link : data.google_compute_network.gitlab_network[0].self_link
  subnet            = local.create_network ? google_compute_subnetwork.gitlab_vpc_subnet[0].self_link : data.google_compute_subnetwork.gitlab_subnet[0].self_link
  zones             = var.zones
  setup_external_ip = var.setup_external_ips
  external_ips      = var.haproxy_external_external_ips

  service_account_prefix       = var.service_account_prefix
  service_account_user_members = var.service_account_user_members
  custom_service_account_email = lookup(var.custom_service_account_emails, "haproxy-external", null)

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment

  tags = ["${var.prefix}-web", "${var.prefix}-ssh", "${var.prefix}-haproxy", "${var.prefix}-monitor"]

  allow_stopping_for_update = var.allow_stopping_for_update
  machine_secure_boot       = var.machine_secure_boot
}

output "haproxy_external" {
  value = module.haproxy_external
}

module "haproxy_internal" {
  source = "../gitlab_gcp_instance"

  prefix     = var.prefix
  node_type  = "haproxy-internal"
  node_count = var.haproxy_internal_node_count
  # TODO: var.additional_labels is deprecated and will be removed in 4.x
  custom_labels = merge(var.additional_labels, var.custom_labels, var.haproxy_internal_custom_labels)

  machine_type  = var.haproxy_internal_machine_type
  machine_image = var.machine_image

  disk_size    = coalesce(var.haproxy_internal_disk_size, var.default_disk_size)
  disk_type    = coalesce(var.haproxy_internal_disk_type, var.default_disk_type)
  disk_kms_key = var.haproxy_internal_disk_kms_key != null ? var.haproxy_internal_disk_kms_key : var.default_disk_kms_key
  disks        = var.haproxy_internal_disks

  vpc               = local.create_network ? google_compute_network.gitlab_vpc[0].self_link : data.google_compute_network.gitlab_network[0].self_link
  subnet            = local.create_network ? google_compute_subnetwork.gitlab_vpc_subnet[0].self_link : data.google_compute_subnetwork.gitlab_subnet[0].self_link
  zones             = var.zones
  setup_external_ip = var.setup_external_ips

  service_account_prefix       = var.service_account_prefix
  service_account_user_members = var.service_account_user_members
  custom_service_account_email = lookup(var.custom_service_account_emails, "haproxy-internal", null)

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment

  tags = ["${var.prefix}-haproxy"]

  allow_stopping_for_update = var.allow_stopping_for_update
  machine_secure_boot       = var.machine_secure_boot
}

output "haproxy_internal" {
  value = module.haproxy_internal
}
