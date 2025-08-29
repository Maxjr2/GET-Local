mock_provider "aws" {}

variables {
  consul_node_count    = 3
  consul_instance_type = "c5.large"

  gitaly_node_count    = 3
  gitaly_instance_type = "m5.4xlarge"

  praefect_node_count    = 3
  praefect_instance_type = "c5.large"

  praefect_postgres_node_count    = 1
  praefect_postgres_instance_type = "c5.large"

  gitlab_rails_node_count    = 3
  gitlab_rails_instance_type = "c5.9xlarge"

  haproxy_external_node_count    = 1
  haproxy_external_instance_type = "c5.xlarge"

  haproxy_internal_node_count    = 1
  haproxy_internal_instance_type = "c5.xlarge"

  monitor_node_count    = 1
  monitor_instance_type = "c5.xlarge"

  opensearch_vm_node_count    = 3
  opensearch_vm_instance_type = "m5.4xlarge"
  opensearch_vm_disk_type     = "gp3"
  opensearch_vm_disk_size     = 100

  pgbouncer_node_count    = 3
  pgbouncer_instance_type = "c5.large"

  postgres_node_count    = 3
  postgres_instance_type = "m5.2xlarge"

  redis_cache_node_count    = 3
  redis_cache_instance_type = "m5.xlarge"

  redis_persistent_node_count    = 3
  redis_persistent_instance_type = "m5.xlarge"

  sidekiq_node_count    = 4
  sidekiq_instance_type = "m5.xlarge"
}

run "mock_aws_10k_environment" {
  command = plan

  module {
    source = "../../../gitlab_ref_arch_aws"
  }

  variables {
    prefix = "gitlab-10k-test"

    # 10k Reference Architecture Configuration
    consul_node_count    = var.consul_node_count
    consul_instance_type = var.consul_instance_type

    gitaly_node_count    = var.gitaly_node_count
    gitaly_instance_type = var.gitaly_instance_type

    praefect_node_count    = var.praefect_node_count
    praefect_instance_type = var.praefect_instance_type

    praefect_postgres_node_count    = var.praefect_postgres_node_count
    praefect_postgres_instance_type = var.praefect_postgres_instance_type

    gitlab_rails_node_count    = var.gitlab_rails_node_count
    gitlab_rails_instance_type = var.gitlab_rails_instance_type

    haproxy_external_node_count    = var.haproxy_external_node_count
    haproxy_external_instance_type = var.haproxy_external_instance_type

    haproxy_internal_node_count    = var.haproxy_internal_node_count
    haproxy_internal_instance_type = var.haproxy_internal_instance_type

    monitor_node_count    = var.monitor_node_count
    monitor_instance_type = var.monitor_instance_type

    opensearch_vm_node_count    = var.opensearch_vm_node_count
    opensearch_vm_instance_type = var.opensearch_vm_instance_type
    opensearch_vm_disk_type     = var.opensearch_vm_disk_type
    opensearch_vm_disk_size     = var.opensearch_vm_disk_size

    pgbouncer_node_count    = var.pgbouncer_node_count
    pgbouncer_instance_type = var.pgbouncer_instance_type

    postgres_node_count    = var.postgres_node_count
    postgres_instance_type = var.postgres_instance_type

    redis_cache_node_count    = var.redis_cache_node_count
    redis_cache_instance_type = var.redis_cache_instance_type

    redis_persistent_node_count    = var.redis_persistent_node_count
    redis_persistent_instance_type = var.redis_persistent_instance_type

    sidekiq_node_count    = var.sidekiq_node_count
    sidekiq_instance_type = var.sidekiq_instance_type
  }

  # Consul assertions
  assert {
    condition     = length(module.consul.instance_ids) == var.consul_node_count
    error_message = "Should create exactly ${var.consul_node_count} Consul EC2 instance(s), but got ${length(module.consul.instance_ids)}"
  }

  assert {
    condition     = module.consul.instance_types[0] == var.consul_instance_type
    error_message = "Consul instance type should be ${var.consul_instance_type}, but got ${module.consul.instance_types[0]}"
  }

  # Gitaly assertions
  assert {
    condition     = length(module.gitaly.instance_ids) == var.gitaly_node_count
    error_message = "Should create exactly ${var.gitaly_node_count} Gitaly EC2 instance(s), but got ${length(module.gitaly.instance_ids)}"
  }

  assert {
    condition     = module.gitaly.instance_types[0] == var.gitaly_instance_type
    error_message = "Gitaly instance type should be ${var.gitaly_instance_type}, but got ${module.gitaly.instance_types[0]}"
  }

  # Praefect assertions
  assert {
    condition     = length(module.praefect.instance_ids) == var.praefect_node_count
    error_message = "Should create exactly ${var.praefect_node_count} Praefect EC2 instance(s), but got ${length(module.praefect.instance_ids)}"
  }

  assert {
    condition     = module.praefect.instance_types[0] == var.praefect_instance_type
    error_message = "Praefect instance type should be ${var.praefect_instance_type}, but got ${module.praefect.instance_types[0]}"
  }

  # Praefect Postgres assertions
  assert {
    condition     = length(module.praefect_postgres.instance_ids) == var.praefect_postgres_node_count
    error_message = "Should create exactly ${var.praefect_postgres_node_count} Praefect Postgres EC2 instance(s), but got ${length(module.praefect_postgres.instance_ids)}"
  }

  assert {
    condition     = module.praefect_postgres.instance_types[0] == var.praefect_postgres_instance_type
    error_message = "Praefect Postgres instance type should be ${var.praefect_postgres_instance_type}, but got ${module.praefect_postgres.instance_types[0]}"
  }

  # GitLab Rails assertions
  assert {
    condition     = length(module.gitlab_rails.instance_ids) == var.gitlab_rails_node_count
    error_message = "Should create exactly ${var.gitlab_rails_node_count} GitLab Rails EC2 instance(s), but got ${length(module.gitlab_rails.instance_ids)}"
  }

  assert {
    condition     = module.gitlab_rails.instance_types[0] == var.gitlab_rails_instance_type
    error_message = "GitLab Rails instance type should be ${var.gitlab_rails_instance_type}, but got ${module.gitlab_rails.instance_types[0]}"
  }

  # HAProxy External assertions
  assert {
    condition     = length(module.haproxy_external.instance_ids) == var.haproxy_external_node_count
    error_message = "Should create exactly ${var.haproxy_external_node_count} HAProxy External EC2 instance(s), but got ${length(module.haproxy_external.instance_ids)}"
  }

  assert {
    condition     = module.haproxy_external.instance_types[0] == var.haproxy_external_instance_type
    error_message = "HAProxy External instance type should be ${var.haproxy_external_instance_type}, but got ${module.haproxy_external.instance_types[0]}"
  }

  # HAProxy Internal assertions
  assert {
    condition     = length(module.haproxy_internal.instance_ids) == var.haproxy_internal_node_count
    error_message = "Should create exactly ${var.haproxy_internal_node_count} HAProxy Internal EC2 instance(s), but got ${length(module.haproxy_internal.instance_ids)}"
  }

  assert {
    condition     = module.haproxy_internal.instance_types[0] == var.haproxy_internal_instance_type
    error_message = "HAProxy Internal instance type should be ${var.haproxy_internal_instance_type}, but got ${module.haproxy_internal.instance_types[0]}"
  }

  # Monitor assertions
  assert {
    condition     = length(module.monitor.instance_ids) == var.monitor_node_count
    error_message = "Should create exactly ${var.monitor_node_count} Monitor EC2 instance(s), but got ${length(module.monitor.instance_ids)}"
  }

  assert {
    condition     = module.monitor.instance_types[0] == var.monitor_instance_type
    error_message = "Monitor instance type should be ${var.monitor_instance_type}, but got ${module.monitor.instance_types[0]}"
  }

  # OpenSearch VM assertions
  assert {
    condition     = length(module.opensearch_vm.instance_ids) == var.opensearch_vm_node_count
    error_message = "Should create exactly ${var.opensearch_vm_node_count} OpenSearch VM EC2 instance(s), but got ${length(module.opensearch_vm.instance_ids)}"
  }

  assert {
    condition     = module.opensearch_vm.instance_types[0] == var.opensearch_vm_instance_type
    error_message = "OpenSearch VM instance type should be ${var.opensearch_vm_instance_type}, but got ${module.opensearch_vm.instance_types[0]}"
  }

  assert {
    condition     = module.opensearch_vm.instance_volume_type[0] == var.opensearch_vm_disk_type
    error_message = "OpenSearch VM volume type should be ${var.opensearch_vm_disk_type}, but got ${module.opensearch_vm.instance_volume_type[0]}"
  }

  assert {
    condition     = module.opensearch_vm.instance_volume_size[0] == tonumber(var.opensearch_vm_disk_size)
    error_message = "OpenSearch VM volume size should be ${var.opensearch_vm_disk_size}, but got ${module.opensearch_vm.instance_volume_size[0]}"
  }

  # PgBouncer assertions
  assert {
    condition     = length(module.pgbouncer.instance_ids) == var.pgbouncer_node_count
    error_message = "Should create exactly ${var.pgbouncer_node_count} PgBouncer EC2 instance(s), but got ${length(module.pgbouncer.instance_ids)}"
  }

  assert {
    condition     = module.pgbouncer.instance_types[0] == var.pgbouncer_instance_type
    error_message = "PgBouncer instance type should be ${var.pgbouncer_instance_type}, but got ${module.pgbouncer.instance_types[0]}"
  }

  # Postgres assertions
  assert {
    condition     = length(module.postgres.instance_ids) == var.postgres_node_count
    error_message = "Should create exactly ${var.postgres_node_count} Postgres EC2 instance(s), but got ${length(module.postgres.instance_ids)}"
  }

  assert {
    condition     = module.postgres.instance_types[0] == var.postgres_instance_type
    error_message = "Postgres instance type should be ${var.postgres_instance_type}, but got ${module.postgres.instance_types[0]}"
  }

  # Redis Cache assertions
  assert {
    condition     = length(module.redis_cache.instance_ids) == var.redis_cache_node_count
    error_message = "Should create exactly ${var.redis_cache_node_count} Redis Cache EC2 instance(s), but got ${length(module.redis_cache.instance_ids)}"
  }

  assert {
    condition     = module.redis_cache.instance_types[0] == var.redis_cache_instance_type
    error_message = "Redis Cache instance type should be ${var.redis_cache_instance_type}, but got ${module.redis_cache.instance_types[0]}"
  }

  # Redis Persistent assertions
  assert {
    condition     = length(module.redis_persistent.instance_ids) == var.redis_persistent_node_count
    error_message = "Should create exactly ${var.redis_persistent_node_count} Redis Persistent EC2 instance(s), but got ${length(module.redis_persistent.instance_ids)}"
  }

  assert {
    condition     = module.redis_persistent.instance_types[0] == var.redis_persistent_instance_type
    error_message = "Redis Persistent instance type should be ${var.redis_persistent_instance_type}, but got ${module.redis_persistent.instance_types[0]}"
  }

  # Sidekiq assertions
  assert {
    condition     = length(module.sidekiq.instance_ids) == var.sidekiq_node_count
    error_message = "Should create exactly ${var.sidekiq_node_count} Sidekiq EC2 instance(s), but got ${length(module.sidekiq.instance_ids)}"
  }

  assert {
    condition     = module.sidekiq.instance_types[0] == var.sidekiq_instance_type
    error_message = "Sidekiq instance type should be ${var.sidekiq_instance_type}, but got ${module.sidekiq.instance_types[0]}"
  }
}
