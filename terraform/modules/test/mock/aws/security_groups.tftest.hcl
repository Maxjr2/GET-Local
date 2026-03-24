# AWS Custom Security Groups Test Suite
# Testing custom_security_group_ids and *_custom_security_group_ids variable propagation to VM nodes

mock_provider "aws" {
  override_during = plan

  override_data {
    target = data.aws_availability_zones.defaults
    values = {
      names = ["us-east-1a", "us-east-1b", "us-east-1c"]
    }
  }

  override_data {
    target = data.aws_partition.current
    values = {
      partition = "aws"
    }
  }

  override_resource {
    target = aws_security_group.gitlab_internal_networking
    values = {
      id = "sg-internal"
    }
  }

  override_resource {
    target = aws_security_group.gitlab_http_https_access[0]
    values = {
      id = "sg-http-https"
    }
  }

  override_resource {
    target = aws_security_group.gitlab_git_ssh_access[0]
    values = {
      id = "sg-git-ssh"
    }
  }
}

variables {
  consul_node_count    = 1
  consul_instance_type = "c5.large"

  gitaly_node_count    = 1
  gitaly_instance_type = "m5.4xlarge"

  gitlab_nfs_node_count    = 1
  gitlab_nfs_instance_type = "c5.large"

  gitlab_rails_node_count    = 1
  gitlab_rails_instance_type = "c5.9xlarge"

  haproxy_external_node_count    = 1
  haproxy_external_instance_type = "c5.large"

  haproxy_internal_node_count    = 1
  haproxy_internal_instance_type = "c5.large"

  monitor_node_count    = 1
  monitor_instance_type = "c5.xlarge"

  opensearch_vm_node_count    = 1
  opensearch_vm_instance_type = "m5.4xlarge"
  opensearch_vm_disk_type     = "gp3"
  opensearch_vm_disk_size     = 100

  pgbouncer_node_count    = 1
  pgbouncer_instance_type = "c5.large"

  postgres_node_count    = 1
  postgres_instance_type = "m5.2xlarge"

  praefect_node_count    = 1
  praefect_instance_type = "c5.large"

  praefect_postgres_node_count    = 1
  praefect_postgres_instance_type = "c5.large"

  redis_node_count    = 1
  redis_instance_type = "m5.xlarge"

  redis_cache_node_count    = 1
  redis_cache_instance_type = "m5.xlarge"

  redis_persistent_node_count    = 1
  redis_persistent_instance_type = "m5.xlarge"

  sidekiq_node_count    = 1
  sidekiq_instance_type = "m5.xlarge"
}

# Test 1: custom_security_group_ids applies to all VM node types
run "custom_security_group_ids_all_nodes" {
  command = plan

  module {
    source = "../../../gitlab_ref_arch_aws"
  }

  variables {
    prefix = "gitlab-sg-test"

    consul_node_count    = var.consul_node_count
    consul_instance_type = var.consul_instance_type

    gitaly_node_count    = var.gitaly_node_count
    gitaly_instance_type = var.gitaly_instance_type

    gitlab_nfs_node_count    = var.gitlab_nfs_node_count
    gitlab_nfs_instance_type = var.gitlab_nfs_instance_type

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

    praefect_node_count    = var.praefect_node_count
    praefect_instance_type = var.praefect_instance_type

    praefect_postgres_node_count    = var.praefect_postgres_node_count
    praefect_postgres_instance_type = var.praefect_postgres_instance_type

    redis_node_count    = var.redis_node_count
    redis_instance_type = var.redis_instance_type

    redis_cache_node_count    = var.redis_cache_node_count
    redis_cache_instance_type = var.redis_cache_instance_type

    redis_persistent_node_count    = var.redis_persistent_node_count
    redis_persistent_instance_type = var.redis_persistent_instance_type

    sidekiq_node_count    = var.sidekiq_node_count
    sidekiq_instance_type = var.sidekiq_instance_type

    custom_security_group_ids = ["sg-global123"]
  }

  assert {
    condition     = contains(module.consul.security_group_ids, "sg-global123")
    error_message = "custom_security_group_ids not applied to consul nodes"
  }

  assert {
    condition     = contains(module.gitaly.security_group_ids, "sg-global123")
    error_message = "custom_security_group_ids not applied to gitaly nodes"
  }

  assert {
    condition     = contains(module.gitlab_nfs.security_group_ids, "sg-global123")
    error_message = "custom_security_group_ids not applied to gitlab_nfs nodes"
  }

  assert {
    condition     = contains(module.gitlab_rails.security_group_ids, "sg-global123")
    error_message = "custom_security_group_ids not applied to gitlab_rails nodes"
  }

  assert {
    condition     = contains(module.haproxy_external.security_group_ids, "sg-global123")
    error_message = "custom_security_group_ids not applied to haproxy_external nodes"
  }

  assert {
    condition     = contains(module.haproxy_internal.security_group_ids, "sg-global123")
    error_message = "custom_security_group_ids not applied to haproxy_internal nodes"
  }

  assert {
    condition     = contains(module.monitor.security_group_ids, "sg-global123")
    error_message = "custom_security_group_ids not applied to monitor nodes"
  }

  assert {
    condition     = contains(module.opensearch_vm.security_group_ids, "sg-global123")
    error_message = "custom_security_group_ids not applied to opensearch_vm nodes"
  }

  assert {
    condition     = contains(module.pgbouncer.security_group_ids, "sg-global123")
    error_message = "custom_security_group_ids not applied to pgbouncer nodes"
  }

  assert {
    condition     = contains(module.postgres.security_group_ids, "sg-global123")
    error_message = "custom_security_group_ids not applied to postgres nodes"
  }

  assert {
    condition     = contains(module.praefect.security_group_ids, "sg-global123")
    error_message = "custom_security_group_ids not applied to praefect nodes"
  }

  assert {
    condition     = contains(module.praefect_postgres.security_group_ids, "sg-global123")
    error_message = "custom_security_group_ids not applied to praefect_postgres nodes"
  }

  assert {
    condition     = contains(module.redis.security_group_ids, "sg-global123")
    error_message = "custom_security_group_ids not applied to redis nodes"
  }

  assert {
    condition     = contains(module.redis_cache.security_group_ids, "sg-global123")
    error_message = "custom_security_group_ids not applied to redis_cache nodes"
  }

  assert {
    condition     = contains(module.redis_persistent.security_group_ids, "sg-global123")
    error_message = "custom_security_group_ids not applied to redis_persistent nodes"
  }

  assert {
    condition     = contains(module.sidekiq.security_group_ids, "sg-global123")
    error_message = "custom_security_group_ids not applied to sidekiq nodes"
  }
}

# Test 2: each *_custom_security_group_ids applies only to its component
run "component_custom_security_group_ids" {
  command = plan

  module {
    source = "../../../gitlab_ref_arch_aws"
  }

  variables {
    prefix = "gitlab-sg-test"

    consul_node_count    = var.consul_node_count
    consul_instance_type = var.consul_instance_type

    gitaly_node_count    = var.gitaly_node_count
    gitaly_instance_type = var.gitaly_instance_type

    gitlab_nfs_node_count    = var.gitlab_nfs_node_count
    gitlab_nfs_instance_type = var.gitlab_nfs_instance_type

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

    praefect_node_count    = var.praefect_node_count
    praefect_instance_type = var.praefect_instance_type

    praefect_postgres_node_count    = var.praefect_postgres_node_count
    praefect_postgres_instance_type = var.praefect_postgres_instance_type

    redis_node_count    = var.redis_node_count
    redis_instance_type = var.redis_instance_type

    redis_cache_node_count    = var.redis_cache_node_count
    redis_cache_instance_type = var.redis_cache_instance_type

    redis_persistent_node_count    = var.redis_persistent_node_count
    redis_persistent_instance_type = var.redis_persistent_instance_type

    sidekiq_node_count    = var.sidekiq_node_count
    sidekiq_instance_type = var.sidekiq_instance_type

    consul_custom_security_group_ids            = ["sg-consul"]
    gitaly_custom_security_group_ids            = ["sg-gitaly"]
    gitlab_nfs_custom_security_group_ids        = ["sg-gitlab-nfs"]
    gitlab_rails_custom_security_group_ids      = ["sg-gitlab-rails"]
    haproxy_external_custom_security_group_ids  = ["sg-haproxy-external"]
    haproxy_internal_custom_security_group_ids  = ["sg-haproxy-internal"]
    monitor_custom_security_group_ids           = ["sg-monitor"]
    opensearch_vm_custom_security_group_ids     = ["sg-opensearch-vm"]
    pgbouncer_custom_security_group_ids         = ["sg-pgbouncer"]
    postgres_custom_security_group_ids          = ["sg-postgres"]
    praefect_custom_security_group_ids          = ["sg-praefect"]
    praefect_postgres_custom_security_group_ids = ["sg-praefect-postgres"]
    redis_custom_security_group_ids             = ["sg-redis"]
    redis_cache_custom_security_group_ids       = ["sg-redis-cache"]
    redis_persistent_custom_security_group_ids  = ["sg-redis-persistent"]
    sidekiq_custom_security_group_ids           = ["sg-sidekiq"]
  }

  assert {
    condition     = contains(module.consul.security_group_ids, "sg-consul") && !contains(module.gitaly.security_group_ids, "sg-consul")
    error_message = "consul_custom_security_group_ids not applied correctly"
  }

  assert {
    condition     = contains(module.gitaly.security_group_ids, "sg-gitaly") && !contains(module.consul.security_group_ids, "sg-gitaly")
    error_message = "gitaly_custom_security_group_ids not applied correctly"
  }

  assert {
    condition     = contains(module.gitlab_nfs.security_group_ids, "sg-gitlab-nfs") && !contains(module.consul.security_group_ids, "sg-gitlab-nfs")
    error_message = "gitlab_nfs_custom_security_group_ids not applied correctly"
  }

  assert {
    condition     = contains(module.gitlab_rails.security_group_ids, "sg-gitlab-rails") && !contains(module.consul.security_group_ids, "sg-gitlab-rails")
    error_message = "gitlab_rails_custom_security_group_ids not applied correctly"
  }

  assert {
    condition     = contains(module.haproxy_external.security_group_ids, "sg-haproxy-external") && !contains(module.consul.security_group_ids, "sg-haproxy-external")
    error_message = "haproxy_external_custom_security_group_ids not applied correctly"
  }

  assert {
    condition     = contains(module.haproxy_internal.security_group_ids, "sg-haproxy-internal") && !contains(module.consul.security_group_ids, "sg-haproxy-internal")
    error_message = "haproxy_internal_custom_security_group_ids not applied correctly"
  }

  assert {
    condition     = contains(module.monitor.security_group_ids, "sg-monitor") && !contains(module.consul.security_group_ids, "sg-monitor")
    error_message = "monitor_custom_security_group_ids not applied correctly"
  }

  assert {
    condition     = contains(module.opensearch_vm.security_group_ids, "sg-opensearch-vm") && !contains(module.consul.security_group_ids, "sg-opensearch-vm")
    error_message = "opensearch_vm_custom_security_group_ids not applied correctly"
  }

  assert {
    condition     = contains(module.pgbouncer.security_group_ids, "sg-pgbouncer") && !contains(module.consul.security_group_ids, "sg-pgbouncer")
    error_message = "pgbouncer_custom_security_group_ids not applied correctly"
  }

  assert {
    condition     = contains(module.postgres.security_group_ids, "sg-postgres") && !contains(module.consul.security_group_ids, "sg-postgres")
    error_message = "postgres_custom_security_group_ids not applied correctly"
  }

  assert {
    condition     = contains(module.praefect.security_group_ids, "sg-praefect") && !contains(module.consul.security_group_ids, "sg-praefect")
    error_message = "praefect_custom_security_group_ids not applied correctly"
  }

  assert {
    condition     = contains(module.praefect_postgres.security_group_ids, "sg-praefect-postgres") && !contains(module.consul.security_group_ids, "sg-praefect-postgres")
    error_message = "praefect_postgres_custom_security_group_ids not applied correctly"
  }

  assert {
    condition     = contains(module.redis.security_group_ids, "sg-redis") && !contains(module.consul.security_group_ids, "sg-redis")
    error_message = "redis_custom_security_group_ids not applied correctly"
  }

  assert {
    condition     = contains(module.redis_cache.security_group_ids, "sg-redis-cache") && !contains(module.consul.security_group_ids, "sg-redis-cache")
    error_message = "redis_cache_custom_security_group_ids not applied correctly"
  }

  assert {
    condition     = contains(module.redis_persistent.security_group_ids, "sg-redis-persistent") && !contains(module.consul.security_group_ids, "sg-redis-persistent")
    error_message = "redis_persistent_custom_security_group_ids not applied correctly"
  }

  assert {
    condition     = contains(module.sidekiq.security_group_ids, "sg-sidekiq") && !contains(module.consul.security_group_ids, "sg-sidekiq")
    error_message = "sidekiq_custom_security_group_ids not applied correctly"
  }
}

# Test 3: Deprecated gitlab_rails_security_group_ids and monitor_security_group_ids are still honoured
run "deprecated_security_group_ids_honoured" {
  command = plan

  module {
    source = "../../../gitlab_ref_arch_aws"
  }

  variables {
    prefix = "gitlab-sg-test"

    gitlab_rails_node_count    = var.gitlab_rails_node_count
    gitlab_rails_instance_type = var.gitlab_rails_instance_type

    monitor_node_count    = var.monitor_node_count
    monitor_instance_type = var.monitor_instance_type

    gitlab_rails_security_group_ids = ["sg-rails-deprecated"]
    monitor_security_group_ids      = ["sg-monitor-deprecated"]
  }

  assert {
    condition     = contains(module.gitlab_rails.security_group_ids, "sg-rails-deprecated")
    error_message = "Deprecated gitlab_rails_security_group_ids not honoured"
  }

  assert {
    condition     = contains(module.monitor.security_group_ids, "sg-monitor-deprecated")
    error_message = "Deprecated monitor_security_group_ids not honoured"
  }
}

# Test 4: *_custom_security_group_ids overrides deprecated *_security_group_ids when both are set
run "custom_security_group_ids_overrides_deprecated" {
  command = plan

  module {
    source = "../../../gitlab_ref_arch_aws"
  }

  variables {
    prefix = "gitlab-sg-test"

    gitlab_rails_node_count    = var.gitlab_rails_node_count
    gitlab_rails_instance_type = var.gitlab_rails_instance_type

    monitor_node_count    = var.monitor_node_count
    monitor_instance_type = var.monitor_instance_type

    gitlab_rails_security_group_ids        = ["sg-rails-deprecated"]
    gitlab_rails_custom_security_group_ids = ["sg-rails-custom"]

    monitor_security_group_ids        = ["sg-monitor-deprecated"]
    monitor_custom_security_group_ids = ["sg-monitor-custom"]
  }

  assert {
    condition     = contains(module.gitlab_rails.security_group_ids, "sg-rails-custom") && !contains(module.gitlab_rails.security_group_ids, "sg-rails-deprecated")
    error_message = "gitlab_rails_custom_security_group_ids should override deprecated gitlab_rails_security_group_ids"
  }

  assert {
    condition     = contains(module.monitor.security_group_ids, "sg-monitor-custom") && !contains(module.monitor.security_group_ids, "sg-monitor-deprecated")
    error_message = "monitor_custom_security_group_ids should override deprecated monitor_security_group_ids"
  }
}
