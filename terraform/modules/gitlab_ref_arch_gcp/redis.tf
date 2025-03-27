module "redis" {
  source = "../gitlab_gcp_instance"

  prefix     = var.prefix
  node_type  = "redis"
  node_count = var.redis_node_count
  # TODO: var.additional_labels is deprecated and will be removed in 4.x
  custom_labels   = merge(var.additional_labels, var.custom_labels, var.redis_custom_labels)
  custom_metadata = merge(var.custom_metadata, var.redis_custom_metadata)

  machine_type  = var.redis_machine_type
  machine_image = var.machine_image

  disk_size    = coalesce(var.redis_disk_size, var.default_disk_size)
  disk_type    = coalesce(var.redis_disk_type, var.default_disk_type)
  disk_kms_key = var.redis_disk_kms_key != null ? var.redis_disk_kms_key : var.default_disk_kms_key
  disks        = var.redis_disks

  vpc               = local.create_network ? google_compute_network.gitlab_vpc[0].self_link : data.google_compute_network.gitlab_network[0].self_link
  subnet            = local.create_network ? google_compute_subnetwork.gitlab_vpc_subnet[0].self_link : data.google_compute_subnetwork.gitlab_subnet[0].self_link
  zones             = var.zones
  setup_external_ip = var.setup_external_ips

  service_account_prefix       = var.service_account_prefix
  service_account_user_members = var.service_account_user_members
  custom_service_account_email = lookup(var.custom_service_account_emails, "redis", null)

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment

  label_secondaries = true

  tags = var.setup_iap_ssh_access ? ["${var.prefix}-iap"] : []

  allow_stopping_for_update = var.allow_stopping_for_update
  machine_secure_boot       = var.machine_secure_boot
}

output "redis" {
  value = module.redis
}

# Redis Separated

module "redis_cache" {
  source = "../gitlab_gcp_instance"

  prefix     = var.prefix
  node_type  = "redis-cache"
  node_count = var.redis_cache_node_count
  # TODO: var.additional_labels is deprecated and will be removed in 4.x
  custom_labels   = merge(var.additional_labels, var.custom_labels, var.redis_cache_custom_labels)
  custom_metadata = merge(var.custom_metadata, var.redis_cache_custom_metadata)

  machine_type  = var.redis_cache_machine_type
  machine_image = var.machine_image

  disk_size    = coalesce(var.redis_cache_disk_size, var.default_disk_size)
  disk_type    = coalesce(var.redis_cache_disk_type, var.default_disk_type)
  disk_kms_key = var.redis_cache_disk_kms_key != null ? var.redis_cache_disk_kms_key : var.default_disk_kms_key
  disks        = var.redis_cache_disks

  vpc               = local.create_network ? google_compute_network.gitlab_vpc[0].self_link : data.google_compute_network.gitlab_network[0].self_link
  subnet            = local.create_network ? google_compute_subnetwork.gitlab_vpc_subnet[0].self_link : data.google_compute_subnetwork.gitlab_subnet[0].self_link
  zones             = var.zones
  setup_external_ip = var.setup_external_ips

  service_account_prefix       = var.service_account_prefix
  service_account_user_members = var.service_account_user_members
  custom_service_account_email = lookup(var.custom_service_account_emails, "redis-cache", null)

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment

  label_secondaries = true

  tags = var.setup_iap_ssh_access ? ["${var.prefix}-iap"] : []

  allow_stopping_for_update = var.allow_stopping_for_update
  machine_secure_boot       = var.machine_secure_boot
}

output "redis_cache" {
  value = module.redis_cache
}

module "redis_persistent" {
  source = "../gitlab_gcp_instance"

  prefix     = var.prefix
  node_type  = "redis-persistent"
  node_count = var.redis_persistent_node_count
  # TODO: var.additional_labels is deprecated and will be removed in 4.x
  custom_labels   = merge(var.additional_labels, var.custom_labels, var.redis_persistent_custom_labels)
  custom_metadata = merge(var.custom_metadata, var.redis_persistent_custom_metadata)

  machine_type  = var.redis_persistent_machine_type
  machine_image = var.machine_image

  disk_size    = coalesce(var.redis_persistent_disk_size, var.default_disk_size)
  disk_type    = coalesce(var.redis_persistent_disk_type, var.default_disk_type)
  disk_kms_key = var.redis_persistent_disk_kms_key != null ? var.redis_persistent_disk_kms_key : var.default_disk_kms_key
  disks        = var.redis_persistent_disks

  vpc               = local.create_network ? google_compute_network.gitlab_vpc[0].self_link : data.google_compute_network.gitlab_network[0].self_link
  subnet            = local.create_network ? google_compute_subnetwork.gitlab_vpc_subnet[0].self_link : data.google_compute_subnetwork.gitlab_subnet[0].self_link
  zones             = var.zones
  setup_external_ip = var.setup_external_ips

  service_account_prefix       = var.service_account_prefix
  service_account_user_members = var.service_account_user_members
  custom_service_account_email = lookup(var.custom_service_account_emails, "redis-persistent", null)

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment

  label_secondaries = true

  tags = var.setup_iap_ssh_access ? ["${var.prefix}-iap"] : []

  allow_stopping_for_update = var.allow_stopping_for_update
  machine_secure_boot       = var.machine_secure_boot
}

output "redis_persistent" {
  value = module.redis_persistent
}
