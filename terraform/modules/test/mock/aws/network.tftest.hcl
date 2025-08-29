# Mock the AWS provider to test networking configurations
mock_provider "aws" {
  override_during = plan

  override_data {
    target = data.aws_availability_zones.defaults
    values = {
      names = ["us-east-1a", "us-east-1b", "us-east-1c"]
    }
  }

  override_resource {
    target = aws_default_vpc.default
    values = {
      id         = "default-vpc"
      cidr_block = "182.31.0.0/16"
    }
  }

  override_resource {
    target = aws_vpc.gitlab_vpc[0]
    values = {
      id         = "created-vpc"
      cidr_block = "172.32.0.0/16"
    }
  }
}

variables {
  default_vpc  = "default-vpc"
  default_cidr = "182.31.0.0/16"

  created_vpc  = "created-vpc"
  created_cidr = "172.32.0.0/16"

  existing_vpc            = "existing-vpc"
  existing_pub_subnet_ids = ["existing-subnet-1", "existing-subnet-2", "existing-subnet-3"]
}

run "mock_aws_default_network" {
  command = plan

  module {
    source = "../../../gitlab_ref_arch_aws"
  }

  variables {
    prefix = "gitlab-test"

    gitlab_rails_node_count    = 1
    gitlab_rails_instance_type = "m5.xlarge"
  }

  assert {
    condition     = output.network.vpc_id == var.default_vpc
    error_message = "Default network should use AWS default VPC ID ${var.default_vpc}, but got ${output.network.vpc_id}"
  }

  assert {
    condition     = output.network.vpc_cidr_block == var.default_cidr
    error_message = "Default network should use AWS default VPC CIDR ${var.default_cidr}, but got ${output.network.vpc_cidr_block}"
  }
}

run "mock_aws_created_network" {
  command = plan

  module {
    source = "../../../gitlab_ref_arch_aws"
  }

  variables {
    prefix = "gitlab-test"

    create_network = true
    vpc_cidr_block = var.created_cidr

    gitlab_rails_node_count    = 1
    gitlab_rails_instance_type = "m5.xlarge"
  }

  assert {
    condition     = output.network.vpc_id == var.created_vpc
    error_message = "Created network should use specified VPC ID ${var.created_vpc}, but got ${output.network.vpc_id}"
  }

  assert {
    condition     = output.network.vpc_cidr_block == var.created_cidr
    error_message = "Created network should use specified VPC CIDR ${var.created_cidr}, but got ${output.network.vpc_cidr_block}"
  }
}

run "mock_aws_existing_network" {
  command = plan

  module {
    source = "../../../gitlab_ref_arch_aws"
  }

  variables {
    prefix = "gitlab-test"

    vpc_id         = var.existing_vpc
    subnet_pub_ids = var.existing_pub_subnet_ids

    gitlab_rails_node_count    = 1
    gitlab_rails_instance_type = "m5.xlarge"
  }

  assert {
    condition     = output.network.vpc_id == var.existing_vpc
    error_message = "Existing network should use specified VPC ID ${var.existing_vpc}, but got ${output.network.vpc_id}"
  }

  assert {
    condition     = toset(output.network.vpc_subnet_pub_ids) == toset(var.existing_pub_subnet_ids)
    error_message = "Existing network should use public subnets [${join(", ", var.existing_pub_subnet_ids)}], but got [${join(", ", output.network.vpc_subnet_pub_ids)}]"
  }
}
