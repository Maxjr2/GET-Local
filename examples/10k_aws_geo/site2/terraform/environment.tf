module "gitlab_ref_arch_aws" {
  source = "../../../modules/gitlab_ref_arch_aws"

  prefix         = var.prefix
  ssh_public_key = file(var.ssh_public_key_file)

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment

  # 10k
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

  haproxy_external_node_count                = 1
  haproxy_external_instance_type             = "c5.large"
  haproxy_external_elastic_ip_allocation_ids = [var.external_ip_allocation]
  haproxy_internal_node_count                = 1
  haproxy_internal_instance_type             = "c5.large"

  monitor_node_count    = 1
  monitor_instance_type = "c5.xlarge"

  pgbouncer_node_count    = 3
  pgbouncer_instance_type = "c5.large"

  postgres_node_count    = 3
  postgres_instance_type = "m5.2xlarge"

  redis_cache_node_count         = 3
  redis_cache_instance_type      = "m5.xlarge"
  redis_persistent_node_count    = 3
  redis_persistent_instance_type = "m5.xlarge"

  sidekiq_node_count    = 4
  sidekiq_instance_type = "m5.xlarge"
}

output "gitlab_ref_arch_aws" {
  value = module.gitlab_ref_arch_aws
}
