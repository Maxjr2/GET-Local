mock_provider "azurerm" {}

variables {
  expected_consul_node_count = 3
  expected_consul_size       = "Standard_F2s_v2"

  expected_gitaly_node_count = 3
  expected_gitaly_size       = "Standard_D16s_v3"

  expected_praefect_node_count = 3
  expected_praefect_size       = "Standard_F2s_v2"

  expected_praefect_postgres_node_count = 1
  expected_praefect_postgres_size       = "Standard_F2s_v2"

  expected_gitlab_rails_node_count = 3
  expected_gitlab_rails_size       = "Standard_F32s_v2"

  expected_haproxy_external_node_count = 1
  expected_haproxy_external_size       = "Standard_F4s_v2"

  expected_haproxy_internal_node_count = 1
  expected_haproxy_internal_size       = "Standard_F4s_v2"

  expected_monitor_node_count = 1
  expected_monitor_size       = "Standard_F4s_v2"

  expected_opensearch_vm_node_count = 3
  expected_opensearch_vm_size       = "Standard_F4s_v2"
  expected_opensearch_vm_disk_size  = 100

  expected_pgbouncer_node_count = 3
  expected_pgbouncer_size       = "Standard_F2s_v2"

  expected_postgres_node_count = 3
  expected_postgres_size       = "Standard_D8s_v3"

  expected_redis_cache_node_count = 3
  expected_redis_cache_size       = "Standard_D4s_v3"

  expected_redis_persistent_node_count = 3
  expected_redis_persistent_size       = "Standard_D4s_v3"

  expected_sidekiq_node_count = 4
  expected_sidekiq_size       = "Standard_D4s_v3"
}

run "mock_azure_10k_environment" {
  command = plan

  module {
    source = "../../../gitlab_ref_arch_azure"
  }

  variables {
    prefix               = "gitlab-10k-test"
    storage_account_name = "gitlab10ktest"
    resource_group_name  = "gitlab-10k-test"
    vm_admin_username    = "gitlab"
    ssh_public_key       = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHixxgIecuJvikK/QZt0ZfI1EYdaXtfgDfm0Fdwx94tt test@example.com"

    # 10k Reference Architecture Configuration
    consul_node_count = var.expected_consul_node_count
    consul_size       = var.expected_consul_size

    gitaly_node_count = var.expected_gitaly_node_count
    gitaly_size       = var.expected_gitaly_size

    praefect_node_count = var.expected_praefect_node_count
    praefect_size       = var.expected_praefect_size

    praefect_postgres_node_count = var.expected_praefect_postgres_node_count
    praefect_postgres_size       = var.expected_praefect_postgres_size

    gitlab_rails_node_count = var.expected_gitlab_rails_node_count
    gitlab_rails_size       = var.expected_gitlab_rails_size

    haproxy_external_node_count = var.expected_haproxy_external_node_count
    haproxy_external_size       = var.expected_haproxy_external_size

    haproxy_internal_node_count = var.expected_haproxy_internal_node_count
    haproxy_internal_size       = var.expected_haproxy_internal_size

    monitor_node_count = var.expected_monitor_node_count
    monitor_size       = var.expected_monitor_size

    opensearch_vm_node_count = var.expected_opensearch_vm_node_count
    opensearch_vm_size       = var.expected_opensearch_vm_size

    pgbouncer_node_count = var.expected_pgbouncer_node_count
    pgbouncer_size       = var.expected_pgbouncer_size

    postgres_node_count = var.expected_postgres_node_count
    postgres_size       = var.expected_postgres_size

    redis_cache_node_count      = var.expected_redis_cache_node_count
    redis_cache_size            = var.expected_redis_cache_size
    redis_persistent_node_count = var.expected_redis_persistent_node_count
    redis_persistent_size       = var.expected_redis_persistent_size

    sidekiq_node_count = var.expected_sidekiq_node_count
    sidekiq_size       = var.expected_sidekiq_size
  }

  # Consul assertions
  assert {
    condition     = length(module.consul.virtual_machine_ids) == var.expected_consul_node_count
    error_message = "Should create exactly ${var.expected_consul_node_count} Consul virtual machine(s), but got ${length(module.consul.virtual_machine_ids)}"
  }

  assert {
    condition     = module.consul.virtual_machine_sizes[0] == var.expected_consul_size
    error_message = "Consul virtual machine size should be ${var.expected_consul_size}, but got ${module.consul.virtual_machine_sizes[0]}"
  }

  # Gitaly assertions
  assert {
    condition     = length(module.gitaly.virtual_machine_ids) == var.expected_gitaly_node_count
    error_message = "Should create exactly ${var.expected_gitaly_node_count} Gitaly virtual machine(s), but got ${length(module.gitaly.virtual_machine_ids)}"
  }

  assert {
    condition     = module.gitaly.virtual_machine_sizes[0] == var.expected_gitaly_size
    error_message = "Gitaly virtual machine size should be ${var.expected_gitaly_size}, but got ${module.gitaly.virtual_machine_sizes[0]}"
  }

  # Praefect assertions
  assert {
    condition     = length(module.praefect.virtual_machine_ids) == var.expected_praefect_node_count
    error_message = "Should create exactly ${var.expected_praefect_node_count} Praefect virtual machine(s), but got ${length(module.praefect.virtual_machine_ids)}"
  }

  assert {
    condition     = module.praefect.virtual_machine_sizes[0] == var.expected_praefect_size
    error_message = "Praefect virtual machine size should be ${var.expected_praefect_size}, but got ${module.praefect.virtual_machine_sizes[0]}"
  }

  # Praefect Postgres assertions
  assert {
    condition     = length(module.praefect_postgres.virtual_machine_ids) == var.expected_praefect_postgres_node_count
    error_message = "Should create exactly ${var.expected_praefect_postgres_node_count} Praefect Postgres virtual machine(s), but got ${length(module.praefect_postgres.virtual_machine_ids)}"
  }

  assert {
    condition     = module.praefect_postgres.virtual_machine_sizes[0] == var.expected_praefect_postgres_size
    error_message = "Praefect Postgres virtual machine size should be ${var.expected_praefect_postgres_size}, but got ${module.praefect_postgres.virtual_machine_sizes[0]}"
  }

  # GitLab Rails assertions
  assert {
    condition     = length(module.gitlab_rails.virtual_machine_ids) == var.expected_gitlab_rails_node_count
    error_message = "Should create exactly ${var.expected_gitlab_rails_node_count} GitLab Rails virtual machine(s), but got ${length(module.gitlab_rails.virtual_machine_ids)}"
  }

  assert {
    condition     = module.gitlab_rails.virtual_machine_sizes[0] == var.expected_gitlab_rails_size
    error_message = "GitLab Rails virtual machine size should be ${var.expected_gitlab_rails_size}, but got ${module.gitlab_rails.virtual_machine_sizes[0]}"
  }

  # HAProxy External assertions
  assert {
    condition     = length(module.haproxy_external.virtual_machine_ids) == var.expected_haproxy_external_node_count
    error_message = "Should create exactly ${var.expected_haproxy_external_node_count} HAProxy External virtual machine(s), but got ${length(module.haproxy_external.virtual_machine_ids)}"
  }

  assert {
    condition     = module.haproxy_external.virtual_machine_sizes[0] == var.expected_haproxy_external_size
    error_message = "HAProxy External virtual machine size should be ${var.expected_haproxy_external_size}, but got ${module.haproxy_external.virtual_machine_sizes[0]}"
  }

  # HAProxy Internal assertions
  assert {
    condition     = length(module.haproxy_internal.virtual_machine_ids) == var.expected_haproxy_internal_node_count
    error_message = "Should create exactly ${var.expected_haproxy_internal_node_count} HAProxy Internal virtual machine(s), but got ${length(module.haproxy_internal.virtual_machine_ids)}"
  }

  assert {
    condition     = module.haproxy_internal.virtual_machine_sizes[0] == var.expected_haproxy_internal_size
    error_message = "HAProxy Internal virtual machine size should be ${var.expected_haproxy_internal_size}, but got ${module.haproxy_internal.virtual_machine_sizes[0]}"
  }

  # Monitor assertions
  assert {
    condition     = length(module.monitor.virtual_machine_ids) == var.expected_monitor_node_count
    error_message = "Should create exactly ${var.expected_monitor_node_count} Monitor virtual machine(s), but got ${length(module.monitor.virtual_machine_ids)}"
  }

  assert {
    condition     = module.monitor.virtual_machine_sizes[0] == var.expected_monitor_size
    error_message = "Monitor virtual machine size should be ${var.expected_monitor_size}, but got ${module.monitor.virtual_machine_sizes[0]}"
  }

  # OpenSearch VM assertions
  assert {
    condition     = length(module.opensearch_vm.virtual_machine_ids) == var.expected_opensearch_vm_node_count
    error_message = "Should create exactly ${var.expected_opensearch_vm_node_count} OpenSearch VM virtual machine(s), but got ${length(module.opensearch_vm.virtual_machine_ids)}"
  }

  assert {
    condition     = module.opensearch_vm.virtual_machine_sizes[0] == var.expected_opensearch_vm_size
    error_message = "OpenSearch VM virtual machine size should be ${var.expected_opensearch_vm_size}, but got ${module.opensearch_vm.virtual_machine_sizes[0]}"
  }

  assert {
    condition     = module.opensearch_vm.virtual_machine_disk_size[0] == var.expected_opensearch_vm_disk_size
    error_message = "OpenSearch VM volume type should be ${var.expected_opensearch_vm_disk_size}, but got ${module.opensearch_vm.virtual_machine_disk_size[0]}"
  }

  # PgBouncer assertions
  assert {
    condition     = length(module.pgbouncer.virtual_machine_ids) == var.expected_pgbouncer_node_count
    error_message = "Should create exactly ${var.expected_pgbouncer_node_count} PgBouncer virtual machine(s), but got ${length(module.pgbouncer.virtual_machine_ids)}"
  }

  assert {
    condition     = module.pgbouncer.virtual_machine_sizes[0] == var.expected_pgbouncer_size
    error_message = "PgBouncer virtual machine size should be ${var.expected_pgbouncer_size}, but got ${module.pgbouncer.virtual_machine_sizes[0]}"
  }

  # Postgres assertions
  assert {
    condition     = length(module.postgres.virtual_machine_ids) == var.expected_postgres_node_count
    error_message = "Should create exactly ${var.expected_postgres_node_count} Postgres virtual machine(s), but got ${length(module.postgres.virtual_machine_ids)}"
  }

  assert {
    condition     = module.postgres.virtual_machine_sizes[0] == var.expected_postgres_size
    error_message = "Postgres virtual machine size should be ${var.expected_postgres_size}, but got ${module.postgres.virtual_machine_sizes[0]}"
  }

  # Redis Cache assertions
  assert {
    condition     = length(module.redis_cache.virtual_machine_ids) == var.expected_redis_cache_node_count
    error_message = "Should create exactly ${var.expected_redis_cache_node_count} Redis Cache virtual machine(s), but got ${length(module.redis_cache.virtual_machine_ids)}"
  }

  assert {
    condition     = module.redis_cache.virtual_machine_sizes[0] == var.expected_redis_cache_size
    error_message = "Redis Cache virtual machine size should be ${var.expected_redis_cache_size}, but got ${module.redis_cache.virtual_machine_sizes[0]}"
  }

  # Redis Persistent assertions
  assert {
    condition     = length(module.redis_persistent.virtual_machine_ids) == var.expected_redis_persistent_node_count
    error_message = "Should create exactly ${var.expected_redis_persistent_node_count} Redis Persistent virtual machine(s), but got ${length(module.redis_persistent.virtual_machine_ids)}"
  }

  assert {
    condition     = module.redis_persistent.virtual_machine_sizes[0] == var.expected_redis_persistent_size
    error_message = "Redis Persistent virtual machine size should be ${var.expected_redis_persistent_size}, but got ${module.redis_persistent.virtual_machine_sizes[0]}"
  }

  # Sidekiq assertions
  assert {
    condition     = length(module.sidekiq.virtual_machine_ids) == var.expected_sidekiq_node_count
    error_message = "Should create exactly ${var.expected_sidekiq_node_count} Sidekiq virtual machine(s), but got ${length(module.sidekiq.virtual_machine_ids)}"
  }

  assert {
    condition     = module.sidekiq.virtual_machine_sizes[0] == var.expected_sidekiq_size
    error_message = "Sidekiq virtual machine size should be ${var.expected_sidekiq_size}, but got ${module.sidekiq.virtual_machine_sizes[0]}"
  }
}
