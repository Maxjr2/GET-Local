output "machine_names" {
  value = google_compute_instance.gitlab[*].name
}

output "internal_addresses" {
  value = {
    for _, v in google_compute_instance.gitlab[*] : "${v.name}.c.${v.project}.internal" => v.network_interface[0].network_ip
  }
}

output "external_addresses" {
  value = var.setup_external_ip ? google_compute_instance.gitlab[*].network_interface[0].access_config[0].nat_ip : []
}

output "self_links" {
  value = google_compute_instance.gitlab[*].self_link
}

output "data_disk_device_names" {
  value = flatten(google_compute_instance.gitlab[*].attached_disk[*].device_name)
}

output "service_account" {
  value = {
    "name"  = try(google_service_account.gitlab[0].name, "")
    "email" = try(google_service_account.gitlab[0].email, "")
  }
}