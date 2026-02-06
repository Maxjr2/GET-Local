# AWS Name Tag Management Test Suite
# Testing default_set_name_tags variable and gitlab_node_name tag behavior

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

  override_data {
    target = data.aws_kms_key.aws_rds
    values = {
      id  = "alias/aws/rds"
      arn = "arn:aws:kms:us-east-1:123456789012:key/aws-rds-key"
    }
  }

  override_data {
    target = data.aws_kms_key.rds_default
    values = {
      id  = "alias/aws/rds"
      arn = "arn:aws:kms:us-east-1:123456789012:key/rds-default-key"
    }
  }

  override_resource {
    target = aws_default_vpc.default
    values = {
      id         = "vpc-default123"
      cidr_block = "172.31.0.0/16"
    }
  }

  override_resource {
    target = aws_vpc.gitlab_vpc[0]
    values = {
      id         = "vpc-created456"
      cidr_block = "10.0.0.0/16"
    }
  }
}

variables {
  test_prefix = "gitlab-tag-test"
}

# Test 1: Comprehensive test with Name tags disabled
run "all_resources_name_tags_disabled" {
  command = plan

  module {
    source = "../../../gitlab_ref_arch_aws"
  }

  variables {
    prefix = var.test_prefix

    default_set_name_tags = false

    # EC2 instances - Multiple node types
    consul_node_count          = 1
    consul_instance_type       = "c5.large"
    gitlab_rails_node_count    = 1
    gitlab_rails_instance_type = "m5.xlarge"

    # Gitaly with data disks to test EBS volume and DLM snapshot policy tags
    gitaly_node_count    = 1
    gitaly_instance_type = "m5.xlarge"
    gitaly_data_disks = [
      { name = "data", device_name = "/dev/sdf", size = 100, snapshot = true, type = "gp3" }
    ]

    # All EKS node pool types
    webservice_node_pool_count         = 1
    webservice_node_pool_instance_type = "m5.xlarge"
    sidekiq_node_pool_count            = 1
    sidekiq_node_pool_instance_type    = "m5.xlarge"
    supporting_node_pool_count         = 1
    supporting_node_pool_instance_type = "m5.large"
    gitaly_node_pool_count             = 1
    gitaly_node_pool_instance_type     = "m5.xlarge"

    # Network resources
    create_network    = true
    vpc_cidr_block    = "10.0.0.0/16"
    subnet_pub_count  = 2
    subnet_priv_count = 2

    # RDS
    rds_postgres_instance_type = "m5.large"
    rds_postgres_password      = "testpassword123456"

    # Unified RDS with CIDR blocks to test security group rules
    rds_databases = {
      main = {
        instance_type       = "m5.large"
        username            = "gitlab"
        password_wo         = "testpassword123456"
        allowed_cidr_blocks = ["10.0.0.0/16", "192.168.1.0/24"]
      }
    }

    # ElastiCache
    elasticache_redis_node_count    = 1
    elasticache_redis_instance_type = "t3.micro"
    elasticache_redis_password      = "testpassword123456"
  }

  # Data disks - Verify volumes are created and have gitlab_node_data_disk_role
  assert {
    condition     = length(module.gitaly.data_disk_volume_ids) > 0
    error_message = "Should create data disk volumes with snapshot policy"
  }

  # All EKS node pool types - Verify NO Name tag on launch templates
  assert {
    condition = alltrue([
      !contains(keys(aws_launch_template.gitlab_webservice[0].tag_specifications[0].tags), "Name"),
      !contains(keys(aws_launch_template.gitlab_sidekiq[0].tag_specifications[0].tags), "Name"),
      !contains(keys(aws_launch_template.gitlab_supporting[0].tag_specifications[0].tags), "Name"),
      !contains(keys(aws_launch_template.gitlab_gitaly[0].tag_specifications[0].tags), "Name"),
      contains(keys(aws_launch_template.gitlab_webservice[0].tag_specifications[0].tags), "gitlab_node_prefix")
    ])
    error_message = "All EKS launch templates should not have Name tag but must have gitlab_node_prefix"
  }

  # All EKS node pool types - Verify volume tag_specifications blocks don't exist (dynamic blocks empty)
  assert {
    condition = alltrue([
      length(aws_launch_template.gitlab_webservice[0].tag_specifications) == 1,
      length(aws_launch_template.gitlab_sidekiq[0].tag_specifications) == 1,
      length(aws_launch_template.gitlab_supporting[0].tag_specifications) == 1,
      length(aws_launch_template.gitlab_gitaly[0].tag_specifications) == 1
    ])
    error_message = "EKS launch templates should only have instance tag_specifications when volume tags are empty"
  }

  # Network resources - Verify NO Name tag
  assert {
    condition = alltrue([
      length(aws_vpc.gitlab_vpc[0].tags) == 0 || !contains(keys(aws_vpc.gitlab_vpc[0].tags), "Name"),
      !contains(keys(aws_subnet.gitlab_vpc_sn_pub[0].tags), "Name"),
      !contains(keys(aws_subnet.gitlab_vpc_sn_priv[0].tags), "Name"),
      length(aws_internet_gateway.gitlab_vpc_gw[0].tags) == 0 || !contains(keys(aws_internet_gateway.gitlab_vpc_gw[0].tags), "Name"),
      length(aws_nat_gateway.gitlab_vpc_sn_priv_ng[0].tags) == 0 || !contains(keys(aws_nat_gateway.gitlab_vpc_sn_priv_ng[0].tags), "Name")
    ])
    error_message = "Network resources should not have Name tag when disabled"
  }

  # Network resources - Verify Kubernetes tags still exist
  assert {
    condition = alltrue([
      contains(keys(aws_subnet.gitlab_vpc_sn_pub[0].tags), "kubernetes.io/role/elb"),
      contains(keys(aws_subnet.gitlab_vpc_sn_priv[0].tags), "kubernetes.io/role/internal-elb")
    ])
    error_message = "Kubernetes tags must be retained on subnets"
  }

  # RDS resources - Verify NO Name tag
  assert {
    condition = alltrue([
      length(aws_db_subnet_group.gitlab[0].tags) == 0 || !contains(keys(aws_db_subnet_group.gitlab[0].tags), "Name"),
      length(aws_db_subnet_group.gitlab_rds_database["main"].tags) == 0 || !contains(keys(aws_db_subnet_group.gitlab_rds_database["main"].tags), "Name")
    ])
    error_message = "RDS subnet groups should not have Name tag when disabled"
  }

  # ElastiCache resources - Verify NO Name tag
  assert {
    condition     = length(aws_elasticache_subnet_group.gitlab_redis[0].tags) == 0 || !contains(keys(aws_elasticache_subnet_group.gitlab_redis[0].tags), "Name")
    error_message = "ElastiCache subnet group should not have Name tag when disabled"
  }

  # Security groups - Verify NO Name tag
  assert {
    condition = alltrue([
      length(aws_security_group.gitlab_internal_networking.tags) == 0 || !contains(keys(aws_security_group.gitlab_internal_networking.tags), "Name"),
      length(aws_security_group.gitlab_rds_database["main"].tags) == 0 || !contains(keys(aws_security_group.gitlab_rds_database["main"].tags), "Name")
    ])
    error_message = "Security groups should not have Name tag when disabled"
  }

  # Security group rules - Verify NO Name tag
  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.gitlab_rds_database_cidr) == 2
    error_message = "Should create 2 CIDR ingress rules for unified RDS"
  }

  assert {
    condition = alltrue([
      for rule_key, rule in aws_vpc_security_group_ingress_rule.gitlab_rds_database_cidr :
      length(rule.tags) == 0 || !contains(keys(rule.tags), "Name")
    ])
    error_message = "Security group ingress rules should not have Name tag when disabled"
  }
}

# Test 2: Comprehensive test with Name tags enabled (default)
run "all_resources_name_tags_enabled" {
  command = plan

  module {
    source = "../../../gitlab_ref_arch_aws"
  }

  variables {
    prefix = var.test_prefix

    # default_set_name_tags defaults to true, so not setting it

    # EC2 instances
    consul_node_count          = 1
    consul_instance_type       = "c5.large"
    gitlab_rails_node_count    = 1
    gitlab_rails_instance_type = "m5.xlarge"

    # EKS to test volume tags are created when Name tag is enabled
    webservice_node_pool_count         = 1
    webservice_node_pool_instance_type = "m5.xlarge"

    # Network resources
    create_network    = true
    vpc_cidr_block    = "10.0.0.0/16"
    subnet_pub_count  = 2
    subnet_priv_count = 2

    # RDS
    rds_postgres_instance_type = "m5.large"
    rds_postgres_password      = "testpassword123456"
  }

  # EKS launch templates - Verify volume tag_specifications blocks exist when Name tag enabled
  assert {
    condition     = length(aws_launch_template.gitlab_webservice[0].tag_specifications) == 2
    error_message = "EKS launch templates should have both instance and volume tag_specifications when Name tag enabled"
  }

  # EKS launch templates - Verify volume tags have Name tag
  assert {
    condition     = contains(keys(aws_launch_template.gitlab_webservice[0].tag_specifications[1].tags), "Name")
    error_message = "EKS volume tag_specifications should have Name tag when enabled (default)"
  }

  # Network resources - Verify Name tag exists
  assert {
    condition = alltrue([
      contains(keys(aws_vpc.gitlab_vpc[0].tags), "Name"),
      contains(keys(aws_subnet.gitlab_vpc_sn_pub[0].tags), "Name"),
      contains(keys(aws_subnet.gitlab_vpc_sn_priv[0].tags), "Name")
    ])
    error_message = "Network resources should have Name tag when enabled (default)"
  }

  # Network resources - Verify Kubernetes tags still exist
  assert {
    condition = alltrue([
      contains(keys(aws_subnet.gitlab_vpc_sn_pub[0].tags), "kubernetes.io/role/elb"),
      contains(keys(aws_subnet.gitlab_vpc_sn_priv[0].tags), "kubernetes.io/role/internal-elb")
    ])
    error_message = "Kubernetes tags must be retained on subnets"
  }

  # RDS resources - Verify Name tag exists
  assert {
    condition     = contains(keys(aws_db_subnet_group.gitlab[0].tags), "Name")
    error_message = "RDS subnet group should have Name tag when enabled (default)"
  }
}

# Section 2: Instance Module Direct Tests
# Testing set_name_tags behavior on EC2 instances and root volumes

run "instance_module_name_tags_disabled" {
  command = plan

  module {
    source = "../../../gitlab_aws_instance"
  }

  variables {
    prefix        = "test-tags"
    node_type     = "gitlab-rails"
    node_count    = 1
    set_name_tags = false
    ami_id        = "ami-test123"
    instance_type = "t3.micro"
  }

  assert {
    condition = alltrue([
      !contains(keys(aws_instance.gitlab[0].tags), "Name"),
      contains(keys(aws_instance.gitlab[0].tags), "gitlab_node_name")
    ])
    error_message = "EC2 instance should not have Name tag but must have gitlab_node_name tag"
  }

  assert {
    condition     = !contains(keys(aws_instance.gitlab[0].root_block_device[0].tags), "Name")
    error_message = "Root volume should not have Name tag when disabled"
  }
}

run "instance_module_name_tags_enabled" {
  command = plan

  module {
    source = "../../../gitlab_aws_instance"
  }

  variables {
    prefix        = "test-tags"
    node_type     = "gitlab-rails"
    node_count    = 1
    ami_id        = "ami-test123"
    instance_type = "t3.micro"
    # set_name_tags defaults to true
  }

  assert {
    condition = alltrue([
      contains(keys(aws_instance.gitlab[0].tags), "Name"),
      contains(keys(aws_instance.gitlab[0].tags), "gitlab_node_name")
    ])
    error_message = "EC2 instance should have both Name and gitlab_node_name tags when enabled"
  }

  assert {
    condition     = aws_instance.gitlab[0].tags["Name"] == aws_instance.gitlab[0].tags["gitlab_node_name"]
    error_message = "Name and gitlab_node_name should have the same value"
  }

  assert {
    condition     = contains(keys(aws_instance.gitlab[0].root_block_device[0].tags), "Name")
    error_message = "Root volume should have Name tag when enabled (default)"
  }
}