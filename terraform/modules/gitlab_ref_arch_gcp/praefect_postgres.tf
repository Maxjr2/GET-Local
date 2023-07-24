module "praefect_postgres" {
  source = "../gitlab_gcp_instance"

  prefix            = var.prefix
  node_type         = "praefect-postgres"
  node_count        = var.praefect_postgres_node_count
  additional_labels = var.additional_labels

  machine_type  = var.praefect_postgres_machine_type
  machine_image = var.machine_image
  disk_size     = coalesce(var.praefect_postgres_disk_size, var.default_disk_size)
  disk_type     = coalesce(var.praefect_postgres_disk_type, var.default_disk_type)
  disks         = var.praefect_postgres_disks

  vpc               = local.vpc_name
  subnet            = local.subnet_name
  zones             = var.zones
  setup_external_ip = var.setup_external_ips

  service_account_prefix = var.service_account_prefix

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment

  label_secondaries = true

  allow_stopping_for_update = var.allow_stopping_for_update
  machine_secure_boot       = var.machine_secure_boot
}

output "praefect_postgres" {
  value = module.praefect_postgres
}
