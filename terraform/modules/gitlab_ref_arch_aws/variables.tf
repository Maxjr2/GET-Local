# General
variable "prefix" {
  description = "Prefix to use on all provisioned resources"
  type        = string
  default     = null

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{2,29}$", var.prefix))
    error_message = "The prefix must be all lowercase alphanumeric characters, between 3 and 30 characters in length."
  }
}

variable "geo_site" {
  type    = string
  default = null
}
variable "geo_deployment" {
  type    = string
  default = null
}

# AWS Settings

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami
variable "ami_id" {
  type    = string
  default = null
}

variable "default_disk_size" {
  type    = string
  default = "100"
}
variable "default_disk_type" {
  type    = string
  default = "gp3"
}
variable "default_disk_delete_on_termination" {
  type    = bool
  default = true
}
variable "default_disk_encrypt" {
  type    = bool
  default = true
}
variable "default_disk_kms_key_arn" {
  type    = string
  default = null
}
variable "default_iam_instance_policy_arns" {
  type    = list(string)
  default = []
}
variable "default_iam_permissions_boundary_arn" {
  type    = string
  default = null
}
variable "default_iam_identifier_path" {
  type    = string
  default = null
}

variable "ssh_public_key" {
  type    = string
  default = null
}

variable "ssh_key_name" {
  description = "Name of an existing AWS Key Pair to use for SSH access to instances. Takes precedence over ssh_public_key if both are provided."
  type        = string
  default     = null
}

variable "object_storage_buckets" {
  type    = list(string)
  default = ["artifacts", "backups", "dependency-proxy", "lfs", "mr-diffs", "packages", "terraform-state", "uploads", "registry", "ci-secure-files", "pages"]
}
variable "object_storage_prefix" {
  type    = string
  default = null
}
variable "object_storage_force_destroy" {
  description = "Toggle to enable force-destruction of S3 Bucket. Consider setting this value to false for production systems"
  type        = bool
  default     = true
}
variable "object_storage_versioning_status" {
  description = "Versioning state of the bucket. Valid values are Enabled, Suspended, or Disabled"
  type        = string
  default     = null
}
variable "object_storage_destination_buckets" {
  description = "A map of buckets to replicate to, format: name = arn"
  type        = map(string)
  default     = null
}
variable "object_storage_replica_kms_key_id" {
  description = "KMS key arn used to encrypt the destination object storage buckets"
  type        = string
  default     = null
}
variable "object_storage_replication_metrics_status" {
  description = "Enable metrics for the S3 replication"
  type        = string
  default     = "Disabled"
}
variable "object_storage_replication_delete_marker_status" {
  description = "Enable replication of delete markers for S3 replication"
  type        = string
  default     = "Enabled"
}
variable "object_storage_kms_key_arn" {
  type    = string
  default = null
}
variable "object_storage_block_public_access" {
  type    = bool
  default = true
}

# Machines
variable "consul_node_count" {
  type    = number
  default = 0
}
variable "consul_instance_type" {
  type    = string
  default = ""
}
variable "consul_disk_type" {
  type    = string
  default = null
}
variable "consul_disk_size" {
  type    = string
  default = null
}
variable "consul_disk_encrypt" {
  type    = bool
  default = null
}
variable "consul_disk_delete_on_termination" {
  type    = bool
  default = true
}
variable "consul_disk_kms_key_arn" {
  type    = string
  default = null
}
variable "consul_data_disks" {
  type = list(
    object({ name = string, device_name = string, type = optional(string), size = optional(number), iops = optional(number), skip_destroy = optional(bool), source_snapshots = optional(map(string)), snapshots = optional(map(string)) })
  )
  default = []
}
variable "consul_iam_instance_policy_arns" {
  type    = list(string)
  default = []
}
variable "consul_user_data_base64" {
  type        = string
  default     = null
  description = "Custom EC2 user data. See https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html for more information"
}

variable "gitaly_node_count" {
  type    = number
  default = 0
}
variable "gitaly_instance_type" {
  type    = string
  default = ""
}
variable "gitaly_disk_type" {
  type    = string
  default = null
}
variable "gitaly_disk_size" {
  type    = string
  default = "500"
}
variable "gitaly_disk_iops" {
  type    = number
  default = 8000
}
variable "gitaly_disk_encrypt" {
  type    = bool
  default = null
}
variable "gitaly_disk_delete_on_termination" {
  type    = bool
  default = true
}
variable "gitaly_disk_kms_key_arn" {
  type    = string
  default = null
}
variable "gitaly_data_disks" {
  type = list(
    object({ name = string, device_name = string, type = optional(string), size = optional(number), iops = optional(number), skip_destroy = optional(bool), source_snapshots = optional(map(string)), snapshots = optional(map(string)) })
  )
  default = []
}
variable "gitaly_iam_instance_policy_arns" {
  type    = list(string)
  default = []
}
variable "gitaly_user_data_base64" {
  type        = string
  default     = null
  description = "Custom EC2 user data. See https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html for more information"
}
variable "gitaly_server_side_backups_enable" {
  type    = bool
  default = false
}

variable "gitlab_nfs_node_count" {
  type    = number
  default = 0
}
variable "gitlab_nfs_instance_type" {
  type    = string
  default = ""
}
variable "gitlab_nfs_disk_type" {
  type    = string
  default = null
}
variable "gitlab_nfs_disk_size" {
  type    = string
  default = null
}
variable "gitlab_nfs_disk_encrypt" {
  type    = bool
  default = null
}
variable "gitlab_nfs_disk_delete_on_termination" {
  type    = bool
  default = true
}
variable "gitlab_nfs_disk_kms_key_arn" {
  type    = string
  default = null
}
variable "gitlab_nfs_data_disks" {
  type = list(
    object({ name = string, device_name = string, type = optional(string), size = optional(number), iops = optional(number), skip_destroy = optional(bool), source_snapshots = optional(map(string)), snapshots = optional(map(string)) })
  )
  default = []
}
variable "gitlab_nfs_iam_instance_policy_arns" {
  type    = list(string)
  default = []
}
variable "gitlab_nfs_user_data_base64" {
  type        = string
  default     = null
  description = "Custom EC2 user data. See https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html for more information"
}

variable "gitlab_rails_node_count" {
  type    = number
  default = 0
}
variable "gitlab_rails_instance_type" {
  type    = string
  default = ""
}
variable "gitlab_rails_disk_type" {
  type    = string
  default = null
}
variable "gitlab_rails_disk_size" {
  type    = string
  default = null
}
variable "gitlab_rails_disk_encrypt" {
  type    = bool
  default = null
}
variable "gitlab_rails_disk_delete_on_termination" {
  type    = bool
  default = true
}
variable "gitlab_rails_disk_kms_key_arn" {
  type    = string
  default = null
}
variable "gitlab_rails_data_disks" {
  type = list(
    object({ name = string, device_name = string, type = optional(string), size = optional(number), iops = optional(number), skip_destroy = optional(bool), source_snapshots = optional(map(string)), snapshots = optional(map(string)) })
  )
  default = []
}
variable "gitlab_rails_iam_instance_policy_arns" {
  type    = list(string)
  default = []
}
variable "gitlab_rails_security_group_ids" {
  description = "List of additional Security Group IDs to apply to GitLab Rails nodes"
  type        = list(string)
  default     = []
}
variable "gitlab_rails_elastic_ip_allocation_ids" {
  description = "List of Elastic IP Allocation IDs to apply to GitLab Rails node"
  type        = list(string)
  default     = []
}
variable "gitlab_rails_user_data_base64" {
  type        = string
  default     = null
  description = "Custom EC2 user data. See https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html for more information"
}

variable "haproxy_external_node_count" {
  type    = number
  default = 0
}
variable "haproxy_external_instance_type" {
  type    = string
  default = ""
}
variable "haproxy_external_disk_type" {
  type    = string
  default = null
}
variable "haproxy_external_disk_size" {
  type    = string
  default = null
}
variable "haproxy_external_disk_encrypt" {
  type    = bool
  default = null
}
variable "haproxy_external_disk_delete_on_termination" {
  type    = bool
  default = true
}
variable "haproxy_external_disk_kms_key_arn" {
  type    = string
  default = null
}
variable "haproxy_external_data_disks" {
  type = list(
    object({ name = string, device_name = string, type = optional(string), size = optional(number), iops = optional(number), skip_destroy = optional(bool), source_snapshots = optional(map(string)), snapshots = optional(map(string)) })
  )
  default = []
}
variable "haproxy_external_elastic_ip_allocation_ids" {
  type    = list(string)
  default = []
}
variable "haproxy_external_iam_instance_policy_arns" {
  type    = list(string)
  default = []
}
variable "haproxy_external_user_data_base64" {
  type        = string
  default     = null
  description = "Custom EC2 user data. See https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html for more information"
}

variable "haproxy_internal_node_count" {
  type    = number
  default = 0
}
variable "haproxy_internal_instance_type" {
  type    = string
  default = ""
}
variable "haproxy_internal_disk_type" {
  type    = string
  default = null
}
variable "haproxy_internal_disk_size" {
  type    = string
  default = null
}
variable "haproxy_internal_disk_encrypt" {
  type    = bool
  default = null
}
variable "haproxy_internal_disk_delete_on_termination" {
  type    = bool
  default = true
}
variable "haproxy_internal_disk_kms_key_arn" {
  type    = string
  default = null
}
variable "haproxy_internal_data_disks" {
  type = list(
    object({ name = string, device_name = string, type = optional(string), size = optional(number), iops = optional(number), skip_destroy = optional(bool), source_snapshots = optional(map(string)), snapshots = optional(map(string)) })
  )
  default = []
}
variable "haproxy_internal_iam_instance_policy_arns" {
  type    = list(string)
  default = []
}
variable "haproxy_internal_user_data_base64" {
  type        = string
  default     = null
  description = "Custom EC2 user data. See https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html for more information"
}

variable "monitor_node_count" {
  type    = number
  default = 0
}
variable "monitor_instance_type" {
  type    = string
  default = ""
}
variable "monitor_disk_type" {
  type    = string
  default = null
}
variable "monitor_disk_size" {
  type    = string
  default = null
}
variable "monitor_disk_encrypt" {
  type    = bool
  default = null
}
variable "monitor_disk_delete_on_termination" {
  type    = bool
  default = true
}
variable "monitor_disk_kms_key_arn" {
  type    = string
  default = null
}
variable "monitor_data_disks" {
  type = list(
    object({ name = string, device_name = string, type = optional(string), size = optional(number), iops = optional(number), skip_destroy = optional(bool), source_snapshots = optional(map(string)), snapshots = optional(map(string)) })
  )
  default = []
}
variable "monitor_iam_instance_policy_arns" {
  type    = list(string)
  default = []
}
variable "monitor_security_group_ids" {
  description = "List of additional Security Group IDs to apply to Monitor nodes"
  type        = list(string)
  default     = []
}
variable "monitor_user_data_base64" {
  type        = string
  default     = null
  description = "Custom EC2 user data. See https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html for more information"
}

# Opensearch (self-managed)
variable "opensearch_vm_node_count" {
  type    = number
  default = 0
}
variable "opensearch_vm_instance_type" {
  type    = string
  default = ""
}
variable "opensearch_vm_disk_type" {
  type    = string
  default = null
}
variable "opensearch_vm_disk_size" {
  type    = string
  default = "500"
}
variable "opensearch_vm_disk_encrypt" {
  type    = bool
  default = null
}
variable "opensearch_vm_disk_delete_on_termination" {
  type    = bool
  default = true
}
variable "opensearch_vm_disk_kms_key_arn" {
  type    = string
  default = null
}
variable "opensearch_vm_data_disks" {
  type = list(
    object({ name = string, device_name = string, type = optional(string), size = optional(number), iops = optional(number), skip_destroy = optional(bool), source_snapshots = optional(map(string)), snapshots = optional(map(string)) })
  )
  default = []
}
variable "opensearch_vm_iam_instance_policy_arns" {
  type    = list(string)
  default = []
}
variable "opensearch_vm_user_data_base64" {
  type        = string
  default     = null
  description = "Custom EC2 user data. See https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html for more information"
}

variable "pgbouncer_node_count" {
  type    = number
  default = 0
}
variable "pgbouncer_instance_type" {
  type    = string
  default = ""
}
variable "pgbouncer_disk_type" {
  type    = string
  default = null
}
variable "pgbouncer_disk_size" {
  type    = string
  default = null
}
variable "pgbouncer_disk_encrypt" {
  type    = bool
  default = null
}
variable "pgbouncer_disk_delete_on_termination" {
  type    = bool
  default = true
}
variable "pgbouncer_disk_kms_key_arn" {
  type    = string
  default = null
}
variable "pgbouncer_data_disks" {
  type = list(
    object({ name = string, device_name = string, type = optional(string), size = optional(number), iops = optional(number), skip_destroy = optional(bool), source_snapshots = optional(map(string)), snapshots = optional(map(string)) })
  )
  default = []
}
variable "pgbouncer_iam_instance_policy_arns" {
  type    = list(string)
  default = []
}
variable "pgbouncer_user_data_base64" {
  type        = string
  default     = null
  description = "Custom EC2 user data. See https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html for more information"
}

variable "postgres_node_count" {
  type    = number
  default = 0
}
variable "postgres_instance_type" {
  type    = string
  default = ""
}
variable "postgres_disk_type" {
  type    = string
  default = null
}
variable "postgres_disk_size" {
  type    = string
  default = null
}
variable "postgres_disk_encrypt" {
  type    = bool
  default = null
}
variable "postgres_disk_delete_on_termination" {
  type    = bool
  default = true
}
variable "postgres_disk_kms_key_arn" {
  type    = string
  default = null
}
variable "postgres_data_disks" {
  type = list(
    object({ name = string, device_name = string, type = optional(string), size = optional(number), iops = optional(number), skip_destroy = optional(bool), source_snapshots = optional(map(string)), snapshots = optional(map(string)) })
  )
  default = []
}
variable "postgres_iam_instance_policy_arns" {
  type    = list(string)
  default = []
}
variable "postgres_user_data_base64" {
  type        = string
  default     = null
  description = "Custom EC2 user data. See https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html for more information"
}

variable "praefect_node_count" {
  type    = number
  default = 0
}
variable "praefect_instance_type" {
  type    = string
  default = ""
}
variable "praefect_disk_type" {
  type    = string
  default = null
}
variable "praefect_disk_size" {
  type    = string
  default = null
}
variable "praefect_disk_encrypt" {
  type    = bool
  default = null
}
variable "praefect_disk_delete_on_termination" {
  type    = bool
  default = true
}
variable "praefect_disk_kms_key_arn" {
  type    = string
  default = null
}
variable "praefect_data_disks" {
  type = list(
    object({ name = string, device_name = string, type = optional(string), size = optional(number), iops = optional(number), skip_destroy = optional(bool), source_snapshots = optional(map(string)), snapshots = optional(map(string)) })
  )
  default = []
}
variable "praefect_iam_instance_policy_arns" {
  type    = list(string)
  default = []
}
variable "praefect_user_data_base64" {
  type        = string
  default     = null
  description = "Custom EC2 user data. See https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html for more information"
}

variable "praefect_postgres_node_count" {
  type    = number
  default = 0
}
variable "praefect_postgres_instance_type" {
  type    = string
  default = ""
}
variable "praefect_postgres_disk_type" {
  type    = string
  default = null
}
variable "praefect_postgres_disk_size" {
  type    = string
  default = null
}
variable "praefect_postgres_disk_encrypt" {
  type    = bool
  default = null
}
variable "praefect_postgres_disk_delete_on_termination" {
  type    = bool
  default = true
}
variable "praefect_postgres_disk_kms_key_arn" {
  type    = string
  default = null
}
variable "praefect_postgres_data_disks" {
  type = list(
    object({ name = string, device_name = string, type = optional(string), size = optional(number), iops = optional(number), skip_destroy = optional(bool), source_snapshots = optional(map(string)), snapshots = optional(map(string)) })
  )
  default = []
}
variable "praefect_postgres_iam_instance_policy_arns" {
  type    = list(string)
  default = []
}
variable "praefect_postgres_user_data_base64" {
  type        = string
  default     = null
  description = "Custom EC2 user data. See https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html for more information"
}

variable "redis_node_count" {
  type    = number
  default = 0
}
variable "redis_instance_type" {
  type    = string
  default = ""
}
variable "redis_disk_type" {
  type    = string
  default = null
}
variable "redis_disk_size" {
  type    = string
  default = null
}
variable "redis_disk_encrypt" {
  type    = bool
  default = null
}
variable "redis_disk_delete_on_termination" {
  type    = bool
  default = true
}
variable "redis_disk_kms_key_arn" {
  type    = string
  default = null
}
variable "redis_data_disks" {
  type = list(
    object({ name = string, device_name = string, type = optional(string), size = optional(number), iops = optional(number), skip_destroy = optional(bool), source_snapshots = optional(map(string)), snapshots = optional(map(string)) })
  )
  default = []
}
variable "redis_iam_instance_policy_arns" {
  type    = list(string)
  default = []
}
variable "redis_user_data_base64" {
  type        = string
  default     = null
  description = "Custom EC2 user data. See https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html for more information"
}

variable "redis_cache_node_count" {
  type    = number
  default = 0
}
variable "redis_cache_instance_type" {
  type    = string
  default = ""
}
variable "redis_cache_disk_type" {
  type    = string
  default = null
}
variable "redis_cache_disk_size" {
  type    = string
  default = null
}
variable "redis_cache_disk_encrypt" {
  type    = bool
  default = null
}
variable "redis_cache_disk_delete_on_termination" {
  type    = bool
  default = true
}
variable "redis_cache_disk_kms_key_arn" {
  type    = string
  default = null
}
variable "redis_cache_data_disks" {
  type = list(
    object({ name = string, device_name = string, type = optional(string), size = optional(number), iops = optional(number), skip_destroy = optional(bool), source_snapshots = optional(map(string)), snapshots = optional(map(string)) })
  )
  default = []
}
variable "redis_cache_iam_instance_policy_arns" {
  type    = list(string)
  default = []
}
variable "redis_cache_user_data_base64" {
  type        = string
  default     = null
  description = "Custom EC2 user data. See https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html for more information"
}

variable "redis_persistent_node_count" {
  type    = number
  default = 0
}
variable "redis_persistent_instance_type" {
  type    = string
  default = ""
}
variable "redis_persistent_disk_type" {
  type    = string
  default = null
}
variable "redis_persistent_disk_size" {
  type    = string
  default = null
}
variable "redis_persistent_disk_encrypt" {
  type    = bool
  default = null
}
variable "redis_persistent_disk_delete_on_termination" {
  type    = bool
  default = true
}
variable "redis_persistent_disk_kms_key_arn" {
  type    = string
  default = null
}
variable "redis_persistent_data_disks" {
  type = list(
    object({ name = string, device_name = string, type = optional(string), size = optional(number), iops = optional(number), skip_destroy = optional(bool), source_snapshots = optional(map(string)), snapshots = optional(map(string)) })
  )
  default = []
}
variable "redis_persistent_iam_instance_policy_arns" {
  type    = list(string)
  default = []
}
variable "redis_persistent_user_data_base64" {
  type        = string
  default     = null
  description = "Custom EC2 user data. See https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html for more information"
}

variable "sidekiq_node_count" {
  type    = number
  default = 0
}
variable "sidekiq_instance_type" {
  type    = string
  default = ""
}
variable "sidekiq_disk_type" {
  type    = string
  default = null
}
variable "sidekiq_disk_size" {
  type    = string
  default = null
}
variable "sidekiq_disk_encrypt" {
  type    = bool
  default = null
}
variable "sidekiq_disk_delete_on_termination" {
  type    = bool
  default = true
}
variable "sidekiq_disk_kms_key_arn" {
  type    = string
  default = null
}
variable "sidekiq_data_disks" {
  type = list(
    object({ name = string, device_name = string, type = optional(string), size = optional(number), iops = optional(number), skip_destroy = optional(bool), source_snapshots = optional(map(string)), snapshots = optional(map(string)) })
  )
  default = []
}
variable "sidekiq_iam_instance_policy_arns" {
  type    = list(string)
  default = []
}
variable "sidekiq_user_data_base64" {
  type        = string
  default     = null
  description = "Custom EC2 user data. See https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html for more information"
}

# EKS - Kubernetes \ Helm
## Defaults
variable "eks_version" {
  type    = string
  default = null
}
variable "eks_default_subnet_count" {
  type    = number
  default = 2
}
variable "eks_endpoint_public_access" {
  type    = bool
  default = true
}
variable "eks_endpoint_public_access_cidr_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}
variable "eks_enabled_cluster_log_types" {
  description = "Array of types of values to be logged to CloudWatch Logs. For possible values, visit https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html"
  type        = list(string)
  default     = []
}
variable "eks_access_config_iam_arns" {
  type    = list(string)
  default = []
}
variable "eks_subnet_ids" {
  description = "List of existing subnet IDs in VPC to be used by the EKS Cluster"
  type        = list(string)
  default     = null
}
variable "eks_default_disk_kms_key_arn" {
  type    = string
  default = null
}
variable "eks_upgrade_policy" {
  type    = string
  default = null
}

## Node Group
variable "eks_node_group_ami_type" {
  description = "Optimised AMI type to use based on machine spec. Can be one of 'AL2_x86_64', 'AL2_ARM_64', 'AL2023_x86_64_STANDARD' or 'AL2023_ARM_64_STANDARD'. Will default to AWS x86 default for EKS version. Ignored if eks_node_group_custom_ami_id is set. For more information visit https://docs.aws.amazon.com/eks/latest/APIReference/API_Nodegroup.html#AmazonEKS-Type-Nodegroup-amiType"
  type        = string
  default     = null
}
variable "eks_node_group_ami_release_version" {
  type    = string
  default = null
}
variable "eks_node_group_ami_force_update_version" {
  type    = bool
  default = null
}

variable "eks_node_group_custom_ami_id" {
  type    = string
  default = null
}
variable "eks_node_group_custom_ami_userdata_type" {
  description = "Userdata type to use for given eks_node_group_custom_ami_id. Can be either 'bootstrap' or 'nodeadm' (AL2023). For more information visit https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html#launch-template-user-data"
  type        = string
  default     = "bootstrap"
}

variable "eks_node_group_subnet_ids" {
  description = "List of existing subnet IDs in VPC to be used by the EKS Node Groups"
  type        = list(string)
  default     = null
}

## Addons Config
variable "eks_kube_proxy_version" {
  type    = string
  default = null
}

variable "eks_coredns_version" {
  type    = string
  default = null
}
variable "eks_coredns_configuration_values" {
  description = "Custom configuration values for CoreDNS addon"
  type        = any
  default     = null

  validation {
    condition     = var.eks_coredns_configuration_values == null || can(jsonencode(var.eks_coredns_configuration_values))
    error_message = "Configuration values must be encodable as JSON"
  }
}

variable "eks_vpc_cni_version" {
  type    = string
  default = null
}

variable "eks_ebs_csi_driver_version" {
  type    = string
  default = null
}

## Namespaces
variable "eks_gitlab_cloud_native_namespace" {
  type    = string
  default = "default"
}

## Secrets Envelope Encryption (Optional)
variable "eks_envelope_encryption" {
  type    = bool
  default = false
}
variable "eks_envelope_kms_key_arn" {
  type    = string
  default = null
}

## Webservice
variable "webservice_node_pool_count" {
  type    = number
  default = 0
}
variable "webservice_node_pool_instance_type" {
  type    = string
  default = ""
}
variable "webservice_node_pool_disk_size" {
  type    = string
  default = null
}
variable "webservice_node_pool_disk_kms_key_arn" {
  type    = string
  default = null
}
## Cluster Autoscaling (Optional)
variable "webservice_node_pool_max_count" {
  type    = number
  default = 0
}
variable "webservice_node_pool_min_count" {
  type    = number
  default = 0
}
## Cluster Updates (Optional)
variable "webservice_node_pool_max_unavailable" {
  type    = number
  default = 0
}

## Sidekiq
variable "sidekiq_node_pool_count" {
  type    = number
  default = 0
}
variable "sidekiq_node_pool_instance_type" {
  type    = string
  default = ""
}
variable "sidekiq_node_pool_disk_size" {
  type    = string
  default = null
}
variable "sidekiq_node_pool_disk_kms_key_arn" {
  type    = string
  default = null
}
## Cluster Autoscaling (Optional)
variable "sidekiq_node_pool_max_count" {
  type    = number
  default = 0
}
variable "sidekiq_node_pool_min_count" {
  type    = number
  default = 0
}
## Cluster Updates (Optional)
variable "sidekiq_node_pool_max_unavailable" {
  type    = number
  default = 0
}

## Supporting
variable "supporting_node_pool_count" {
  type    = number
  default = 0
}
variable "supporting_node_pool_instance_type" {
  type    = string
  default = ""
}
variable "supporting_node_pool_disk_size" {
  type    = string
  default = null
}
variable "supporting_node_pool_disk_kms_key_arn" {
  type    = string
  default = null
}
## Cluster Autoscaling (Optional)
variable "supporting_node_pool_max_count" {
  type    = number
  default = 0
}
variable "supporting_node_pool_min_count" {
  type    = number
  default = 0
}
## Cluster Updates (Optional)
variable "supporting_node_pool_max_unavailable" {
  type    = number
  default = 0
}

## [Toolkit Beta] Gitaly on Kubernetes. Known limitations, see https://docs.gitlab.com/administration/gitaly/kubernetes/
variable "gitaly_node_pool_count" {
  type    = number
  default = 0
}
variable "gitaly_node_pool_instance_type" {
  type    = string
  default = ""
}
variable "gitaly_node_pool_disk_size" {
  type    = string
  default = null
}
variable "gitaly_node_pool_disk_kms_key_arn" {
  type    = string
  default = null
}
## Cluster Autoscaling (Optional)
variable "gitaly_node_pool_max_count" {
  type    = number
  default = 0
}
variable "gitaly_node_pool_min_count" {
  type    = number
  default = 0
}
## Cluster Updates (Optional)
variable "gitaly_node_pool_max_unavailable" {
  type    = number
  default = 0
}

# PaaS Services
## PostgreSQL
variable "rds_postgres_instance_type" {
  type    = string
  default = ""
}
variable "rds_postgres_port" {
  type    = number
  default = 5432
}
variable "rds_postgres_username" {
  type    = string
  default = "gitlab"
}
variable "rds_postgres_password" {
  type      = string
  default   = ""
  sensitive = true
}
variable "rds_postgres_database_name" {
  type    = string
  default = "gitlabhq_production"
}
variable "rds_postgres_version" {
  type    = string
  default = "16"
}
variable "rds_postgres_auto_minor_version_upgrade" {
  type    = bool
  default = false
}
variable "rds_postgres_allocated_storage" {
  type    = number
  default = 100
}
variable "rds_postgres_max_allocated_storage" {
  type    = number
  default = 1000
}
variable "rds_postgres_multi_az" {
  type    = bool
  default = true
}
variable "rds_postgres_default_subnet_count" {
  type    = number
  default = 2
}
variable "rds_postgres_subnet_ids" {
  description = "List of existing subnet IDs in VPC to be used by RDS instance"
  type        = list(string)
  default     = null
}
variable "rds_postgres_iops" {
  type    = number
  default = null
}
variable "rds_postgres_storage_type" {
  type    = string
  default = "io1"
}
variable "rds_postgres_kms_key_arn" {
  type    = string
  default = null
}
variable "rds_postgres_replication_database_arn" {
  type    = string
  default = null
}
variable "rds_postgres_backup_retention_period" {
  type    = number
  default = null
}
variable "rds_postgres_backup_window" {
  type    = string
  default = null
}
variable "rds_postgres_delete_automated_backups" {
  type    = bool
  default = null
}
variable "rds_postgres_maintenance_window" {
  type    = string
  default = null
}
variable "rds_postgres_ca_cert_identifier" {
  type    = string
  default = null
}
variable "rds_postgres_iam_database_authentication_enabled" {
  type    = bool
  default = true
}
variable "rds_postgres_params" {
  description = "Additional RDS parameter group settings"
  type        = any
  default     = {}
}
variable "rds_postgres_create_timeout" {
  description = "How long to wait for the create to finish before timing out"
  type        = string
  default     = "2h"
}
variable "rds_postgres_lifecycle_support" {
  description = "Support lifecycle for the database, Extended or Standard. Accepted values are `open-source-rds-extended-support` or `open-source-rds-extended-support-disabled`"
  type        = string
  default     = null
}
variable "rds_snapshot_identifier" {
  description = "Specifies whether or not to create this database from a snapshot. This correlates to the snapshot ID you'd find in the RDS console"
  type        = string
  default     = null
}

variable "rds_postgres_read_replica_count" {
  type    = number
  default = 0
}
variable "rds_postgres_read_replica_port" {
  type    = number
  default = 5432
}
variable "rds_postgres_read_replica_multi_az" {
  type    = bool
  default = false
}
variable "rds_postgres_read_replica_create_timeout" {
  description = "How long to wait for the create to finish before timing out"
  type        = string
  default     = "2h"
}
variable "rds_postgres_enabled_cloudwatch_logs_exports" {
  description = "Log types to export to Cloudwatch. For Postgres, valid values are `postgresql` and  `upgrade`"
  type        = list(string)
  default     = []
}
variable "rds_postgres_monitoring_interval" {
  description = "The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance. Valid Values: 0, 1, 5, 10, 15, 30, 60."
  type        = number
  default     = 0
}
variable "rds_postgres_monitoring_role_arn" {
  description = "An assumable IAM Role used to publish RDS logs to Cloudwatch"
  type        = string
  default     = null
}
variable "rds_postgres_deletion_protection" {
  type    = bool
  default = false
}

variable "rds_postgres_read_replica_deletion_protection" {
  type    = bool
  default = false
}

variable "rds_postgres_performance_insights_enabled" {
  description = "Enables AWS RDS Performance Insights"
  type        = bool
  default     = null
}
variable "rds_postgres_performance_insights_retention_period" {
  description = "Sets the retention period for AWS RDS Performance Insights"
  type        = number
  default     = null
}


## Praefect PostgreSQL
variable "rds_praefect_postgres_instance_type" {
  type    = string
  default = ""
}
variable "rds_praefect_postgres_port" {
  type    = number
  default = 5432
}
variable "rds_praefect_postgres_username" {
  type    = string
  default = "praefect"
}
variable "rds_praefect_postgres_password" {
  type    = string
  default = ""
}
variable "rds_praefect_postgres_database_name" {
  type    = string
  default = "praefect_production"
}
variable "rds_praefect_postgres_version" {
  type    = string
  default = "16"
}
variable "rds_praefect_postgres_auto_minor_version_upgrade" {
  type    = bool
  default = false
}
variable "rds_praefect_postgres_allocated_storage" {
  type    = number
  default = 100
}
variable "rds_praefect_postgres_max_allocated_storage" {
  type    = number
  default = 1000
}
variable "rds_praefect_postgres_multi_az" {
  type    = bool
  default = true
}
variable "rds_praefect_postgres_default_subnet_count" {
  type    = number
  default = 2
}
variable "rds_praefect_postgres_subnet_ids" {
  description = "List of existing subnet IDs in VPC to be used by RDS instance"
  type        = list(string)
  default     = null
}
variable "rds_praefect_postgres_iops" {
  type    = number
  default = null
}
variable "rds_praefect_postgres_storage_type" {
  type    = string
  default = "io1"
}
variable "rds_praefect_postgres_kms_key_arn" {
  type    = string
  default = null
}
variable "rds_praefect_postgres_backup_retention_period" {
  type    = number
  default = null
}
variable "rds_praefect_postgres_backup_window" {
  type    = string
  default = null
}
variable "rds_praefect_postgres_delete_automated_backups" {
  type    = bool
  default = null
}
variable "rds_praefect_postgres_maintenance_window" {
  type    = string
  default = null
}
variable "rds_praefect_postgres_ca_cert_identifier" {
  type    = string
  default = null
}
variable "rds_praefect_postgres_iam_database_authentication_enabled" {
  type    = bool
  default = true
}
variable "rds_praefect_postgres_params" {
  description = "Additional RDS Praefect parameter group settings"
  type        = map(any)
  default     = {}
}
variable "rds_praefect_postgres_create_timeout" {
  description = "How long to wait for the create to finish before timing out"
  type        = string
  default     = "2h"
}
variable "rds_praefect_postgres_lifecycle_support" {
  description = "Support lifecycle for the database, Extended or Standard. Accepted values are `open-source-rds-extended-support` or `open-source-rds-extended-support-disabled`"
  type        = string
  default     = null
}

variable "rds_praefect_postgres_read_replica_count" {
  type    = number
  default = 0
}
variable "rds_praefect_postgres_read_replica_port" {
  type    = number
  default = 5432
}
variable "rds_praefect_postgres_read_replica_multi_az" {
  type    = bool
  default = false
}
variable "rds_praefect_postgres_read_replica_create_timeout" {
  description = "How long to wait for the create to finish before timing out"
  type        = string
  default     = "2h"
}
variable "rds_praefect_postgres_enabled_cloudwatch_logs_exports" {
  description = "Log types to export to Cloudwatch. For Postgres, valid values are `postgresql` and  `upgrade`"
  type        = list(string)
  default     = []
}
variable "rds_praefect_postgres_monitoring_interval" {
  description = "The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance. Valid Values: 0, 1, 5, 10, 15, 30, 60."
  type        = number
  default     = 0
}
variable "rds_praefect_postgres_monitoring_role_arn" {
  description = "An assumable IAM Role used to publish RDS logs to Cloudwatch"
  type        = string
  default     = null
}
variable "rds_praefect_postgres_deletion_protection" {
  type    = bool
  default = false
}
variable "rds_praefect_snapshot_identifier" {
  description = "Specifies whether or not to create this database from a snapshot. This correlates to the snapshot ID you'd find in the RDS console"
  type        = string
  default     = null
}

## Geo Tracking PostgreSQL
variable "rds_geo_tracking_postgres_instance_type" {
  type    = string
  default = ""
}
variable "rds_geo_tracking_postgres_port" {
  type    = number
  default = 5431
}
variable "rds_geo_tracking_postgres_username" {
  type    = string
  default = "gitlab_geo"
}
variable "rds_geo_tracking_postgres_password" {
  type    = string
  default = ""
}
variable "rds_geo_tracking_postgres_database_name" {
  type    = string
  default = "gitlabhq_geo_production"
}
variable "rds_geo_tracking_postgres_version" {
  type    = string
  default = "16"
}
variable "rds_geo_tracking_postgres_auto_minor_version_upgrade" {
  type    = bool
  default = false
}
variable "rds_geo_tracking_postgres_allocated_storage" {
  type    = number
  default = 100
}
variable "rds_geo_tracking_postgres_max_allocated_storage" {
  type    = number
  default = 1000
}
variable "rds_geo_tracking_postgres_multi_az" {
  type    = bool
  default = true
}
variable "rds_geo_tracking_default_subnet_count" {
  type    = number
  default = 2
}
variable "rds_geo_tracking_postgres_subnet_ids" {
  description = "List of existing subnet IDs in VPC to be used by RDS instance"
  type        = list(string)
  default     = null
}
variable "rds_geo_tracking_postgres_iops" {
  type    = number
  default = null
}
variable "rds_geo_tracking_postgres_storage_type" {
  type    = string
  default = "io1"
}
variable "rds_geo_tracking_postgres_kms_key_arn" {
  type    = string
  default = null
}
variable "rds_geo_tracking_postgres_backup_retention_period" {
  type    = number
  default = null
}
variable "rds_geo_tracking_postgres_backup_window" {
  type    = string
  default = null
}
variable "rds_geo_tracking_postgres_delete_automated_backups" {
  type    = bool
  default = null
}
variable "rds_geo_tracking_postgres_maintenance_window" {
  type    = string
  default = null
}
variable "rds_geo_tracking_postgres_ca_cert_identifier" {
  type    = string
  default = null
}
variable "rds_geo_tracking_postgres_iam_database_authentication_enabled" {
  type    = bool
  default = true
}
variable "rds_geo_tracking_postgres_params" {
  description = "Additional RDS Geo Tracking parameter group settings"
  type        = map(any)
  default     = {}
}
variable "rds_geo_tracking_postgres_create_timeout" {
  description = "How long to wait for the create to finish before timing out"
  type        = string
  default     = "2h"
}
variable "rds_geo_tracking_postgres_lifecycle_support" {
  description = "Support lifecycle for the database, Extended or Standard. Accepted values are `open-source-rds-extended-support` or `open-source-rds-extended-support-disabled`"
  type        = string
  default     = null
}

variable "rds_geo_tracking_postgres_read_replica_count" {
  type    = number
  default = 0
}
variable "rds_geo_tracking_postgres_read_replica_port" {
  type    = number
  default = 5432
}
variable "rds_geo_tracking_postgres_read_replica_multi_az" {
  type    = bool
  default = false
}
variable "rds_geo_tracking_postgres_read_replica_create_timeout" {
  description = "How long to wait for the create to finish before timing out"
  type        = string
  default     = "2h"
}
variable "rds_geo_tracking_postgres_enabled_cloudwatch_logs_exports" {
  description = "Log types to export to Cloudwatch. For Postgres, valid values are `postgresql` and  `upgrade`"
  type        = list(string)
  default     = []
}
variable "rds_geo_tracking_postgres_monitoring_interval" {
  description = "The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance. Valid Values: 0, 1, 5, 10, 15, 30, 60."
  type        = number
  default     = 0
}
variable "rds_geo_tracking_postgres_monitoring_role_arn" {
  description = "An assumable IAM Role used to publish RDS logs to Cloudwatch"
  type        = string
  default     = null
}
variable "rds_geo_tracking_postgres_deletion_protection" {
  type    = bool
  default = false
}
variable "rds_geo_tracking_snapshot_identifier" {
  description = "Specifies whether or not to create this database from a snapshot. This correlates to the snapshot ID you'd find in the RDS console"
  type        = string
  default     = null
}

## [Toolkit Beta] Unified RDS PostgreSQL
variable "rds_databases" {
  description = "Map of RDS PostgreSQL databases to create"
  type = map(object({
    # Main configuration
    instance_type       = string
    username            = optional(string, "postgres")
    password_wo         = optional(string, null)
    password_wo_version = optional(number, 1)
    version             = optional(string, "16")
    db_name             = optional(string, null)
    port                = optional(number, 5432)

    # Storage
    allocated_storage     = optional(number, 100)
    max_allocated_storage = optional(number, 1000)
    storage_type          = optional(string, "gp3")
    iops                  = optional(number, null)

    # High availability & reliability
    multi_az            = optional(bool, null)
    deletion_protection = optional(bool, null)

    # Networking
    subnet_ids           = optional(list(string), null)
    default_subnet_count = optional(number, 2)

    # Security
    allowed_cidr_blocks                 = optional(list(string), [])
    kms_key_arn                         = optional(string, null)
    ca_cert_identifier                  = optional(string, null)
    iam_database_authentication_enabled = optional(bool, null)

    # Backup & Maintenance settings
    backup_retention_period    = optional(number, null)
    backup_window              = optional(string, null)
    delete_automated_backups   = optional(bool, null)
    maintenance_window         = optional(string, null)
    auto_minor_version_upgrade = optional(bool, false)

    # Monitoring & logging
    enabled_cloudwatch_logs_exports       = optional(list(string), [])
    monitoring_interval                   = optional(number, null)
    monitoring_role_arn                   = optional(string, null)
    performance_insights                  = optional(bool, null)
    performance_insights_retention_period = optional(number, null)

    # Read replica configuration
    read_replica_count               = optional(number, 0)
    read_replica_port                = optional(number, null)
    read_replica_multi_az            = optional(bool, null)
    read_replica_deletion_protection = optional(bool, null)

    # Advanced options
    lifecycle_support    = optional(string, "open-source-rds-extended-support-disabled")
    create_timeout       = optional(string, "2h")
    snapshot_identifier  = optional(string, null)
    replicate_source_arn = optional(string, null)
    parameters           = optional(map(any), {})
    custom_tags          = optional(map(string), {})
  }))
  default = {}
}

## Redis
### Combined \ Defaults
variable "elasticache_redis_node_count" {
  type    = number
  default = 0
}
variable "elasticache_redis_instance_type" {
  type    = string
  default = ""
}
variable "elasticache_redis_kms_key_arn" {
  type    = string
  default = null
}
variable "elasticache_redis_engine" {
  type    = string
  default = "redis"

  validation {
    condition     = contains(["redis", "valkey"], var.elasticache_redis_engine)
    error_message = "Engine must be either 'redis' or 'valkey'."
  }
}
variable "elasticache_redis_engine_version" {
  type    = string
  default = "7.0"
}
variable "elasticache_redis_password" {
  type      = string
  default   = ""
  sensitive = true
}
variable "elasticache_redis_port" {
  type    = number
  default = 6379
}
variable "elasticache_redis_multi_az" {
  type    = bool
  default = true
}
variable "elasticache_redis_subnet_ids" {
  description = "List of existing subnet IDs in VPC to be used by the Elasticache instance"
  type        = list(string)
  default     = null
}
variable "elasticache_redis_maintenance_window" {
  type    = string
  default = null
}
variable "elasticache_redis_snapshot_retention_limit" {
  type    = number
  default = null
}
variable "elasticache_redis_snapshot_window" {
  type    = string
  default = null
}
variable "elasticache_redis_final_snapshot_identifier" {
  description = "Name of final snapshot to create if cluster is destroyed. If null no snapshot is created."
  type        = string
  default     = null
}
variable "elasticache_redis_snapshot_name" {
  description = "Name of a snapshot from which to restore data into the new node group. Changing this setting forces a new resource."
  type        = string
  default     = null
}
variable "elasticache_redis_default_subnet_count" {
  type    = number
  default = 2
}

### Separate - Cache
variable "elasticache_redis_cache_node_count" {
  type    = number
  default = 0
}
variable "elasticache_redis_cache_instance_type" {
  type    = string
  default = ""
}
variable "elasticache_redis_cache_kms_key_arn" {
  type    = string
  default = null
}
variable "elasticache_redis_cache_engine" {
  type    = string
  default = "redis"

  validation {
    condition     = contains(["redis", "valkey"], var.elasticache_redis_cache_engine)
    error_message = "Engine must be either 'redis' or 'valkey'."
  }
}
variable "elasticache_redis_cache_engine_version" {
  type    = string
  default = null
}
variable "elasticache_redis_cache_password" {
  type      = string
  default   = ""
  sensitive = true
}
variable "elasticache_redis_cache_port" {
  type    = number
  default = null
}
variable "elasticache_redis_cache_multi_az" {
  type    = bool
  default = null
}
variable "elasticache_redis_cache_maintenance_window" {
  type    = string
  default = null
}
variable "elasticache_redis_cache_snapshot_retention_limit" {
  type    = number
  default = null
}
variable "elasticache_redis_cache_snapshot_window" {
  type    = string
  default = null
}
variable "elasticache_redis_cache_final_snapshot_identifier" {
  description = "Name of final snapshot to create if cluster is destroyed. If null no snapshot is created."
  type        = string
  default     = null
}
variable "elasticache_redis_cache_snapshot_name" {
  description = "Name of a snapshot from which to restore data into the new node group. Changing this setting forces a new resource."
  type        = string
  default     = null
}

### Separate - Persistent
variable "elasticache_redis_persistent_node_count" {
  type    = number
  default = 0
}
variable "elasticache_redis_persistent_instance_type" {
  type    = string
  default = ""
}
variable "elasticache_redis_persistent_kms_key_arn" {
  type    = string
  default = null
}
variable "elasticache_redis_persistent_engine" {
  type    = string
  default = "redis"

  validation {
    condition     = contains(["redis", "valkey"], var.elasticache_redis_persistent_engine)
    error_message = "Engine must be either 'redis' or 'valkey'."
  }
}
variable "elasticache_redis_persistent_engine_version" {
  type    = string
  default = null
}
variable "elasticache_redis_persistent_password" {
  type      = string
  default   = ""
  sensitive = true
}
variable "elasticache_redis_persistent_port" {
  type    = number
  default = null
}
variable "elasticache_redis_persistent_multi_az" {
  type    = bool
  default = null
}
variable "elasticache_redis_persistent_maintenance_window" {
  type    = string
  default = null
}
variable "elasticache_redis_persistent_snapshot_retention_limit" {
  type    = number
  default = null
}
variable "elasticache_redis_persistent_snapshot_window" {
  type    = string
  default = null
}
variable "elasticache_redis_persistent_final_snapshot_identifier" {
  description = "Name of final snapshot to create if cluster is destroyed. If null no snapshot is created."
  type        = string
  default     = null
}
variable "elasticache_redis_persistent_snapshot_name" {
  description = "Name of a snapshot from which to restore data into the new node group. Changing this setting forces a new resource."
  type        = string
  default     = null
}

## OpenSearch (AWS Service)
variable "opensearch_service_node_count" {
  type    = number
  default = 0
}
variable "opensearch_service_instance_type" {
  type    = string
  default = ""
}
variable "opensearch_service_master_node_count" {
  type    = number
  default = null
}
variable "opensearch_service_master_instance_type" {
  type    = string
  default = null
}
variable "opensearch_service_warm_node_count" {
  type    = number
  default = null
}
variable "opensearch_service_warm_instance_type" {
  type    = string
  default = null
}
variable "opensearch_service_engine_version" {
  type    = string
  default = null
}
variable "opensearch_service_volume_size" {
  type    = number
  default = 500
}
variable "opensearch_service_volume_type" {
  type    = string
  default = "io1"
}
variable "opensearch_service_volume_iops" {
  type    = number
  default = null
}
variable "opensearch_service_volume_throughput" {
  type    = number
  default = null
}
variable "opensearch_service_multi_az" {
  type    = bool
  default = true
}
variable "opensearch_service_default_subnet_count" {
  type    = number
  default = 2
}
variable "opensearch_service_subnet_ids" {
  description = "List of existing subnet IDs in VPC to be used by the OpenSearch Cluster"
  type        = list(string)
  default     = null
}
variable "opensearch_service_kms_key_arn" {
  type    = string
  default = null
}
variable "opensearch_service_linked_role_create" {
  type    = bool
  default = false
}

# Networking
## Created
variable "create_network" {
  type    = bool
  default = false
}
variable "create_network_routes" {
  type    = bool
  default = true
}
variable "vpc_cidr_block" {
  type    = string
  default = "172.31.0.0/16"
}
variable "subnet_pub_cidr_block" {
  type    = list(string)
  default = ["172.31.0.0/20", "172.31.16.0/20", "172.31.32.0/20"]
}
variable "subnet_pub_count" {
  type    = number
  default = 2
}
variable "subnet_priv_cidr_block" {
  type    = list(string)
  default = ["172.31.128.0/20", "172.31.144.0/20", "172.31.160.0/20"]
}
variable "subnet_priv_count" {
  type    = number
  default = 0
}
variable "zones_exclude" {
  type    = list(string)
  default = null
}
variable "availability_zones" {
  type    = list(string)
  default = []
}

## Existing
variable "vpc_id" {
  type    = string
  default = null
}
variable "subnet_pub_ids" {
  type    = list(string)
  default = null
}
variable "subnet_priv_ids" {
  type    = list(string)
  default = null
}

## Peering
variable "peer_region" {
  description = "AWS region for the VPC network to create a peering connection with"
  type        = string
  default     = null
}
variable "peer_connection_id" {
  description = "ID for the peering connection made between each VPC"
  type        = string
  default     = null
}
variable "peer_vpc_id" {
  description = "VPC ID for the VPC network to create a peering connection with"
  type        = string
  default     = null
}
variable "peer_vpc_cidr" {
  description = "CIDR for the VPC network to create a peering connection with"
  type        = string
  default     = null
}

## Security Groups
variable "default_allowed_ingress_cidr_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "http_allowed_ingress_cidr_blocks" {
  type    = list(any)
  default = []
}
variable "external_ssh_allowed_ingress_cidr_blocks" {
  type    = list(any)
  default = []
}

variable "ssh_allowed_ingress_cidr_blocks" {
  type    = list(any)
  default = []
}
variable "gitlab_shell_ssh_port" {
  type    = number
  default = null
}

variable "internal_allowed_ingress_security_group_ids" {
  description = "List of additional Security Group IDs to allow access to Internal Networking group"
  type        = list(string)
  default     = []
}

### Services (Internal)
variable "rds_postgres_allowed_ingress_cidr_blocks" {
  type    = list(any)
  default = []
}
variable "rds_praefect_postgres_allowed_ingress_cidr_blocks" {
  type    = list(any)
  default = []
}
variable "rds_geo_tracking_postgres_allowed_ingress_cidr_blocks" {
  type    = list(any)
  default = []
}

variable "elasticache_redis_allowed_ingress_cidr_blocks" {
  type    = list(any)
  default = []
}
variable "elasticache_redis_cache_allowed_ingress_cidr_blocks" {
  type    = list(any)
  default = []
}
variable "elasticache_redis_persistent_allowed_ingress_cidr_blocks" {
  type    = list(any)
  default = []
}

variable "opensearch_service_allowed_ingress_cidr_blocks" {
  type    = list(any)
  default = []
}

# AWS Load Balancers
## Internal
variable "elb_internal_create" {
  type    = bool
  default = false
}
variable "elb_internal_praefect_port" {
  type    = number
  default = 2305
}


# Tags
variable "custom_tags" {
  type    = map(string)
  default = {}
}
variable "consul_custom_tags" {
  type    = map(string)
  default = {}
}
variable "gitaly_custom_tags" {
  type    = map(string)
  default = {}
}
variable "gitlab_rails_custom_tags" {
  type    = map(string)
  default = {}
}
variable "haproxy_external_custom_tags" {
  type    = map(string)
  default = {}
}
variable "haproxy_internal_custom_tags" {
  type    = map(string)
  default = {}
}
variable "monitor_custom_tags" {
  type    = map(string)
  default = {}
}
variable "object_storage_custom_tags" {
  type    = map(string)
  default = {}
}
variable "object_storage_buckets_custom_tags" {
  type    = map(any)
  default = {}
}
variable "opensearch_vm_custom_tags" {
  type    = map(string)
  default = {}
}
variable "pgbouncer_custom_tags" {
  type    = map(string)
  default = {}
}
variable "postgres_custom_tags" {
  type    = map(string)
  default = {}
}
variable "praefect_postgres_custom_tags" {
  type    = map(string)
  default = {}
}
variable "praefect_custom_tags" {
  type    = map(string)
  default = {}
}
variable "redis_custom_tags" {
  type    = map(string)
  default = {}
}
variable "redis_cache_custom_tags" {
  type    = map(string)
  default = {}
}
variable "redis_persistent_custom_tags" {
  type    = map(string)
  default = {}
}
variable "sidekiq_custom_tags" {
  type    = map(string)
  default = {}
}

variable "elb_internal_custom_tags" {
  type    = map(string)
  default = {}
}

variable "eks_custom_tags" {
  type    = map(string)
  default = {}
}
variable "webservice_node_pool_custom_tags" {
  type    = map(string)
  default = {}
}
variable "sidekiq_node_pool_custom_tags" {
  type    = map(string)
  default = {}
}
variable "supporting_node_pool_custom_tags" {
  type    = map(string)
  default = {}
}
## [Toolkit Beta] Gitaly on Kubernetes. Known limitations, see https://docs.gitlab.com/administration/gitaly/kubernetes/
variable "gitaly_node_pool_custom_tags" {
  type    = map(string)
  default = {}
}

variable "elasticache_redis_custom_tags" {
  type    = map(string)
  default = {}
}
variable "elasticache_redis_cache_custom_tags" {
  type    = map(string)
  default = {}
}
variable "elasticache_redis_persistent_custom_tags" {
  type    = map(string)
  default = {}
}

variable "opensearch_service_custom_tags" {
  type    = map(string)
  default = {}
}

variable "rds_postgres_custom_tags" {
  type    = map(string)
  default = {}
}
variable "rds_geo_tracking_postgres_custom_tags" {
  type    = map(string)
  default = {}
}
variable "rds_praefect_postgres_custom_tags" {
  type    = map(string)
  default = {}
}

# Deprecated - To be removed in 4.x
variable "additional_tags" {
  description = "Deprecated. Replaced by custom_tags."
  type        = map(any)
  default     = {}
}
variable "elasticache_redis_tags" {
  description = "Deprecated. Replaced by elasticache_redis_custom_tags."
  type        = map(any)
  default     = {}
}
variable "elasticache_redis_cache_tags" {
  description = "Deprecated. Replaced by elasticache_redis_cache_custom_tags."
  type        = map(any)
  default     = {}
}
variable "elasticache_redis_persistent_tags" {
  description = "Deprecated. Replaced by elasticache_redis_persistent_custom_tags."
  type        = map(any)
  default     = {}
}
variable "object_storage_tags" {
  description = "Deprecated. Replaced by object_storage_custom_tags."
  type        = map(any)
  default     = {}
}
variable "opensearch_service_tags" {
  description = "Deprecated. Replaced by opensearch_service_custom_tags."
  type        = map(any)
  default     = {}
}
variable "rds_geo_tracking_postgres_tags" {
  description = "Deprecated. Replaced by rds_geo_tracking_postgres_custom_tags."
  type        = map(any)
  default     = {}
}
variable "rds_postgres_tags" {
  description = "Deprecated. Replaced by rds_postgres_custom_tags."
  type        = map(any)
  default     = {}
}
variable "rds_praefect_postgres_tags" {
  description = "Deprecated. Replaced by rds_praefect_postgres_custom_tags."
  type        = map(any)
  default     = {}
}
variable "eks_ami_id" {
  description = "Deprecated. Replaced by eks_node_group_custom_ami_id"
  type        = string
  default     = null
}
variable "external_ssh_port" {
  description = "Deprecated. Replaced by gitlab_shell_ssh_port"
  type        = number
  default     = 2222
}
variable "default_kms_key_arn" {
  description = "Deprecated. Replaced by default_disk_kms_key_arn, object_storage_kms_key_arn, eks_default_disk_kms_key_arn, rds_postgres_kms_key_arn, elasticache_redis_kms_key_arn and opensearch_service_kms_key_arn"
  type        = string
  default     = null
}

variable "eks_gitlab_charts_namespace" {
  description = "Deprecated. Replaced by eks_gitlab_cloud_native_namespace"
  type        = string
  default     = null
}

variable "object_storage_versioning" {
  description = "Deprecated. Replaced by object_storage_versioning_status"
  type        = bool
  default     = null
}