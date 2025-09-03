output "machine_names" {
  value = azurerm_linux_virtual_machine.gitlab[*].name
}

output "internal_addresses" {
  value = {
    for _, v in azurerm_linux_virtual_machine.gitlab[*] : "${v.name}.internal.cloudapp.net" => v.private_ip_address
  }
}

output "external_addresses" {
  value = var.setup_external_ip ? azurerm_linux_virtual_machine.gitlab[*].public_ip_address : []
}

output "virtual_machine_ids" {
  value = azurerm_linux_virtual_machine.gitlab[*].virtual_machine_id
}

output "virtual_machine_sizes" {
  value = azurerm_linux_virtual_machine.gitlab[*].size
}

output "virtual_machine_disk_size" {
  value = try(azurerm_linux_virtual_machine.gitlab[*].os_disk[0].disk_size_gb, 0)
}

output "data_disk_names" {
  value = [for k, v in azurerm_managed_disk.gitlab : v.name]
}

output "data_disk_ids" {
  description = "Azure Managed Disk IDs for data disks provisioned for this instance."
  value       = [for k, v in azurerm_managed_disk.gitlab : v.id]
}
