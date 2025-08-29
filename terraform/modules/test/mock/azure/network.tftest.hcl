
mock_provider "azurerm" {}

run "mock_azure_1k_environment" {
  command = plan

  module {
    source = "../../../gitlab_ref_arch_azure"
  }

  variables {
    prefix               = "gitlab-1k-test"
    storage_account_name = "gitlab1ktest"
    resource_group_name  = "gitlab-1k-test"
    vm_admin_username    = "gitlab"
    ssh_public_key       = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHixxgIecuJvikK/QZt0ZfI1EYdaXtfgDfm0Fdwx94tt test@example.com"

    gitlab_rails_node_count = 1
    gitlab_rails_size       = "Standard_F32s_v2"
  }

  assert {
    condition     = output.network.vpc_name != null
    error_message = "Default network should provide VPC"
  }

  assert {
    condition     = output.network.vpc_subnet[0] == "172.17.0.0/16"
    error_message = "Default network should use Azure default subnet"
  }
}
