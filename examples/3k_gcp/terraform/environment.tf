module "gitlab_ref_arch_gcp" {
  source = "../../modules/gitlab_ref_arch_gcp"

  prefix  = var.prefix
  project = var.project

  # 3k
  consul_node_count   = 3
  consul_machine_type = "n1-highcpu-2"

  gitaly_node_count   = 3
  gitaly_machine_type = "n1-standard-4"

  praefect_node_count   = 3
  praefect_machine_type = "n1-highcpu-2"

  praefect_postgres_node_count   = 1
  praefect_postgres_machine_type = "n1-highcpu-2"

  gitlab_rails_node_count   = 3
  gitlab_rails_machine_type = "n1-highcpu-8"

  haproxy_external_node_count   = 1
  haproxy_external_machine_type = "n1-highcpu-2"
  haproxy_external_external_ips = [var.external_ip]
  haproxy_internal_node_count   = 1
  haproxy_internal_machine_type = "n1-highcpu-2"

  monitor_node_count   = 1
  monitor_machine_type = "n1-highcpu-2"

  pgbouncer_node_count   = 3
  pgbouncer_machine_type = "n1-highcpu-2"

  postgres_node_count   = 3
  postgres_machine_type = "n1-standard-2"

  redis_node_count   = 3
  redis_machine_type = "n1-standard-2"

  sidekiq_node_count   = 4
  sidekiq_machine_type = "n1-standard-2"
}

output "gitlab_ref_arch_gcp" {
  value = module.gitlab_ref_arch_gcp
}
