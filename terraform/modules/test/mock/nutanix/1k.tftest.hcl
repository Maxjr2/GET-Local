mock_provider "nutanix" {}

run "mock_nutanix_1k_environment" {
  command = plan

  module {
    source = "../../../gitlab_ref_arch_nutanix"
  }

  variables {
    prefix                 = "gitlab-1k-test"
    cluster_uuid           = "00000000-0000-0000-0000-000000000001"
    subnet_uuid            = "00000000-0000-0000-0000-000000000002"
    image_uuid             = "00000000-0000-0000-0000-000000000003"
    storage_container_uuid = "00000000-0000-0000-0000-000000000004"
    vm_admin_username      = "gitlab"
    ssh_public_key         = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHixxgIecuJvikK/QZt0ZfI1EYdaXtfgDfm0Fdwx94tt test@example.com"

    gitlab_rails_node_count = 1
    gitlab_rails_size = {
      num_sockets          = 4
      num_vcpus_per_socket = 2
      memory_size_mib      = 8192
    }
  }

  assert {
    condition     = length(output.gitlab_rails.machine_names) == 1
    error_message = "GitLab Rails should provision exactly 1 node"
  }

  assert {
    condition     = output.gitlab_rails.machine_names[0] == "gitlab-1k-test-gitlab-rails-1"
    error_message = "GitLab Rails VM should be named using prefix and node type"
  }

  assert {
    condition     = length(output.gitaly.machine_names) == 0
    error_message = "Gitaly should not provision any nodes when node_count defaults to 0"
  }
}

run "mock_nutanix_multi_component" {
  command = plan

  module {
    source = "../../../gitlab_ref_arch_nutanix"
  }

  variables {
    prefix                 = "gitlab-multi-test"
    cluster_uuid           = "00000000-0000-0000-0000-000000000001"
    subnet_uuid            = "00000000-0000-0000-0000-000000000002"
    image_uuid             = "00000000-0000-0000-0000-000000000003"
    storage_container_uuid = "00000000-0000-0000-0000-000000000004"
    vm_admin_username      = "gitlab"
    ssh_public_key         = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHixxgIecuJvikK/QZt0ZfI1EYdaXtfgDfm0Fdwx94tt test@example.com"

    gitaly_node_count       = 2
    postgres_node_count     = 1
    redis_node_count        = 1
    gitlab_rails_node_count = 1
  }

  assert {
    condition     = length(output.gitaly.machine_names) == 2
    error_message = "Gitaly should provision 2 nodes"
  }

  assert {
    condition     = output.gitaly.machine_names[1] == "gitlab-multi-test-gitaly-2"
    error_message = "Second Gitaly node should be named with -2 suffix"
  }

  assert {
    condition     = length(output.postgres.machine_names) == 1
    error_message = "Postgres should provision exactly 1 node"
  }
}
