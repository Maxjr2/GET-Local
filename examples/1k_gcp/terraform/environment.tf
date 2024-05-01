module "gitlab_ref_arch_gcp" {
  source = "../../modules/gitlab_ref_arch_gcp"

  prefix  = var.prefix
  project = var.project

  # 1k
  gitlab_rails_node_count   = 1
  gitlab_rails_machine_type = "n1-standard-8"

  haproxy_external_node_count   = 1
  haproxy_external_machine_type = "n1-highcpu-2"
  haproxy_external_external_ips = [var.external_ip]
}

output "gitlab_ref_arch_gcp" {
  value = module.gitlab_ref_arch_gcp
}
