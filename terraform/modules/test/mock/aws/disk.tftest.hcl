mock_provider "aws" {
  override_data {
    target = data.aws_partition.current
    values = {
      partition = "aws"
    }
  }
}

# Block 1: gp3 guard + defaults - must run first (fresh resource) since run blocks share state.
# disk_throughput=500 is supplied but disk_type=gp2, so the guard produces throughput=null (0).
# Also verifies iops defaults to null (0) when not set.
run "mock_aws_disk_guard_and_defaults" {
  command = apply

  module {
    source = "../../../gitlab_aws_instance"
  }

  variables {
    prefix          = "gitlab-disk-test"
    node_type       = "gitaly"
    node_count      = 1
    disk_type       = "gp2"
    disk_throughput = 500
    ami_id          = "ami-12345678"
  }

  assert {
    condition     = output.instance_volume_iops[0] == 0
    error_message = "Default disk IOPS should be 0 (null), but got ${output.instance_volume_iops[0]}"
  }

  assert {
    condition     = output.instance_volume_throughput[0] == 0
    error_message = "Throughput should be null/0 for non-gp3 disk type, but got ${output.instance_volume_throughput[0]}"
  }
}

# Block 2: Custom iops + throughput on gp3
run "mock_aws_disk_custom_gp3" {
  command = apply

  module {
    source = "../../../gitlab_aws_instance"
  }

  variables {
    prefix          = "gitlab-disk-test"
    node_type       = "gitaly"
    node_count      = 1
    disk_type       = "gp3"
    disk_iops       = 10000
    disk_throughput = 500
    ami_id          = "ami-12345678"
  }

  assert {
    condition     = output.instance_volume_iops[0] == 10000
    error_message = "Disk IOPS should be 10000, but got ${output.instance_volume_iops[0]}"
  }

  assert {
    condition     = output.instance_volume_throughput[0] == 500
    error_message = "Disk throughput should be 500, but got ${output.instance_volume_throughput[0]}"
  }
}
