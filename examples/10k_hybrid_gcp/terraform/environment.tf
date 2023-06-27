module "gitlab_ref_arch_gcp" {
  source = "../../modules/gitlab_ref_arch_gcp"

  prefix  = var.prefix
  project = var.project

  # 10k Hybrid - k8s Node Pools
  webservice_node_pool_count        = 4
  webservice_node_pool_machine_type = "n1-highcpu-32"

  sidekiq_node_pool_count        = 4
  sidekiq_node_pool_machine_type = "n1-standard-4"

  supporting_node_pool_count        = 2
  supporting_node_pool_machine_type = "n1-standard-4"

  # 10k Hybrid - Compute VMs
  consul_node_count   = 3
  consul_machine_type = "n1-highcpu-2"

  gitaly_node_count   = 3
  gitaly_machine_type = "n1-standard-16"

  praefect_node_count   = 3
  praefect_machine_type = "n1-highcpu-2"

  praefect_postgres_node_count   = 1
  praefect_postgres_machine_type = "n1-highcpu-2"

  haproxy_internal_node_count   = 1
  haproxy_internal_machine_type = "n1-highcpu-2"

  pgbouncer_node_count   = 3
  pgbouncer_machine_type = "n1-highcpu-2"

  postgres_node_count   = 3
  postgres_machine_type = "n1-standard-8"

  redis_cache_node_count        = 3
  redis_cache_machine_type      = "n1-standard-4"
  redis_persistent_node_count   = 3
  redis_persistent_machine_type = "n1-standard-4"
}

output "gitlab_ref_arch_gcp" {
  value = module.gitlab_ref_arch_gcp
}
