# Nutanix categories are the equivalent of AWS/GCP/Azure tags, but every category
# value must be pre-created before it can be attached to a VM. This file creates
# the category keys and the specific values that the component modules below will
# use, based on which components are enabled (node_count > 0).

locals {
  component_node_counts = {
    consul            = var.consul_node_count
    gitaly            = var.gitaly_node_count
    gitlab-nfs        = var.gitlab_nfs_node_count
    gitlab-rails      = var.gitlab_rails_node_count
    haproxy-external  = var.haproxy_external_node_count
    haproxy-internal  = var.haproxy_internal_node_count
    monitor           = var.monitor_node_count
    opensearch        = var.opensearch_vm_node_count
    pgbouncer         = var.pgbouncer_node_count
    postgres          = var.postgres_node_count
    praefect          = var.praefect_node_count
    praefect-postgres = var.praefect_postgres_node_count
    redis             = var.redis_node_count
    redis-cache       = var.redis_cache_node_count
    redis-persistent  = var.redis_persistent_node_count
    sidekiq           = var.sidekiq_node_count
  }

  node_type_values = { for k, v in local.component_node_counts : k => k if v > 0 }

  node_level_values = merge([
    for k, v in local.component_node_counts : v > 0 ? {
      "${k}-primary"   = true
      "${k}-secondary" = true
    } : {}
  ]...)
}

resource "nutanix_category_key" "gitlab" {
  for_each    = toset(["gitlab_node_prefix", "gitlab_node_type", "gitlab_node_level", "gitlab_geo_site", "gitlab_geo_deployment"])
  name        = each.key
  description = "Managed by GitLab Environment Toolkit"
}

resource "nutanix_category_value" "node_prefix" {
  name  = nutanix_category_key.gitlab["gitlab_node_prefix"].id
  value = var.prefix
}

resource "nutanix_category_value" "node_type" {
  for_each = local.node_type_values
  name     = nutanix_category_key.gitlab["gitlab_node_type"].id
  value    = each.value
}

resource "nutanix_category_value" "node_level" {
  for_each = local.node_level_values
  name     = nutanix_category_key.gitlab["gitlab_node_level"].id
  value    = each.key
}

resource "nutanix_category_value" "geo_site" {
  count = var.geo_site == null ? 0 : 1
  name  = nutanix_category_key.gitlab["gitlab_geo_site"].id
  value = var.geo_site
}

resource "nutanix_category_value" "geo_deployment" {
  count = var.geo_deployment == null ? 0 : 1
  name  = nutanix_category_key.gitlab["gitlab_geo_deployment"].id
  value = var.geo_deployment
}
