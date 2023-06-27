module "gitlab_ref_arch_aws" {
  source = "../../modules/gitlab_ref_arch_aws"

  prefix         = var.prefix
  ssh_public_key = file(var.ssh_public_key_file)

  create_network      = true
  subnet_pub_count    = 3
  elb_internal_create = true

  # 10k - K8s
  webservice_node_pool_count         = 4
  webservice_node_pool_instance_type = "c5.9xlarge"

  sidekiq_node_pool_count         = 4
  sidekiq_node_pool_instance_type = "m5.xlarge"

  supporting_node_pool_count         = 2
  supporting_node_pool_instance_type = "m5.xlarge"

  gitaly_node_count    = 3
  gitaly_instance_type = "m5.4xlarge"

  praefect_node_count    = 3
  praefect_instance_type = "c5.large"

  # 10k - AWS RDS
  rds_postgres_instance_type = "m5.2xlarge"
  rds_postgres_password      = "<rds_password>"

  elasticache_redis_cache_node_count    = 2
  elasticache_redis_cache_instance_type = "m5.xlarge"
  elasticache_redis_cache_password      = "<elasticache_cache_password>"

  elasticache_redis_persistent_node_count    = 2
  elasticache_redis_persistent_instance_type = "m5.xlarge"
  elasticache_redis_persistent_password      = "<elasticache_persistent_password>"
}

output "gitlab_ref_arch_aws" {
  value = module.gitlab_ref_arch_aws
}
