output "machine_names" {
  value = nutanix_virtual_machine.gitlab[*].name
}

output "internal_addresses" {
  value = {
    for v in nutanix_virtual_machine.gitlab : v.name => try(v.nic_list_status[0].ip_endpoint_list[0].ip, null)
  }
}

output "virtual_machine_ids" {
  value = nutanix_virtual_machine.gitlab[*].id
}

output "virtual_machine_sizes" {
  value = [
    for v in nutanix_virtual_machine.gitlab : {
      num_sockets          = v.num_sockets
      num_vcpus_per_socket = v.num_vcpus_per_socket
      memory_size_mib      = v.memory_size_mib
    }
  ]
}
