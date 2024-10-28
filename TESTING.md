# GitLab Environment Toolkit - Testing

Due to the lack of viable mock testing for Ansible and Terraform, testing for the GitLab Environment Toolkit requires deploying full environments on cloud infrastructure. The same is true when using the Toolkit to test out specific deployments for investigation or debugging purposes.

As such, testing of the Toolkit is done in as efficient manner as possible with select automated pipelines with a high coverage matrix as well as ad hoc testing when required.

**For benefit of doubt - Deploying to cloud infrastructure always results in costs, sometimes significant, and as a result testing in this manner should only be done when necessary such as when testing a new Toolkit feature or when a scaled GitLab environment is needed as part of an investigation.**

[[_TOC_]]

## Reduced Testing Cost Options

The Toolkit has been designed to have reasonable defaults for production deployments. If it is deemed necessary to use the Toolkit for testing these defaults can be adjusted to reduce the cost accordingly depending on the context. Refer to each section below for more options:

:information_source:&nbsp; Adjusting options as given in this guide must only be done for testing purposes. These adjustments should not be done for production environments unless it's understood to not be impactful.

### General

#### Instance Counts & Sizes

Instance count and sizes are blank by default for both VMs and all Cloud Services. However when using the Toolkit for testing it's not required to use the exact counts and sizings for a particular [Reference Architecture](https://docs.gitlab.com/ee/administration/reference_architectures) size.

Unless you're deploying an environment for Performance or HA test purposes it's recommended to deploy the smallest environment size required for what you're looking to test. Additionally you can further deploy smaller instance sizes and counts. As a general guide 2 CPU core boxes are sufficient for deploying GitLab components in a functioning way.

#### Non-HA Variants (Postgres, Gitaly, Redis)

If HA isn't a concern for testing you can choose to deploy the non-HA setups of various components such as Redis, Postgres and Gitaly in Terraform as follows:

- Redis - Reduce Redis node count to 1
- Postgres - Reduce Postgres node count to 1 and PgBouncer node count to 0. If monitoring isn't a concern you can also then reduce Consul node count to 0
- Gitaly - Reduce Gitaly node count to 1 and Praefect & Praefect Postgres node count to 0.

#### Select component reconfigure requirements

Select components in the GitLab stack will require a reconfigure if resized notably after deploying. This is to ensure the component's config is adjusted to match the node specs.

At the time of writing GitLab Rails and Postgres need to be reconfigured after a resize to adjust Puma workers and Postgres config accordingly. This can be done by running the `gitlab-ctl reconfigure` command on the specific boxes or by running the equivalent Ansible playbook with the `reconfigure` tag - `ansible-playbook -i <inventory>  playbooks/gitlab_rails.yml playbooks/postgres.yml -t reconfigure`.

### AWS

The following options have default values set in the AWS Terraform module (default given in `[]` brackets) that can be adjusted to reduce costs:

#### EC2 Disks

[Documentation](docs/environment_provision.md#configure-module-settings-environmenttf-1)

- `default_disk_size` [`100`] - Applies to all VMs and Kubernetes Node Pools except for the ones noted below:
  - `gitaly_disk_size` [`500`].
  - `opensearch_vm_disk_size` [`500`].
- `gitaly_disk_iops` [`8000`] - The default here is the recommendation for running Gitaly in production. But for testing purposes this can be reduce to the [minimum of `3000`](https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-plan-storage-compare-volume-types.html) if performance isn't a factor.

#### RDS

[Documentation](docs/environment_advanced_services.md#aws-rds)

- `rds_postgres_allocated_storage` [`100`] - Initial disk size.
  - Note that this is automatically increases as required by AWS up to the max limit set by `rds_postgres_max_allocated_storage` [`1000`]
- `rds_postgres_storage_type` [`io1`] - Disk type, can be switched to `gp3` to save costs.
  - `rds_postgres_iops` [`null`] is also available but the Toolkit automatically sets this to the minimum available for the selected storage type.
- `rds_postgres_multi_az` [`true`] - If a standby replica is configured. Can be switched to `false` to reduce costs.

#### OpenSearch Service

- `opensearch_service_volume_size` [`500`]
- `opensearch_service_volume_type` [`io1`] - Disk type, can be switched to `gp3` to save costs.
  - `opensearch_service_volume_iops` [`null`] is also available but the Toolkit automatically sets this to the minimum available for the selected storage type.
- `opensearch_service_multi_az` [`true`] - If a standby replica is configured. Can be switched to `false` to reduce costs but this will flip to `false` automatically when `opensearch_service_node_count` has be set to `1` as well.

#### Other notes

- Deploying AWS Elasticache instances with a node count of 1 disables any standby replicas - This is sufficient for testing.
- Enabling [Cluster Autoscaler for AWS EKS clusters](docs/environment_advanced_hybrid.md#eks-cluster-autoscaling) can lead to savings if testing is expected to last a while.
- When deploying EKS clusters with provisioned volume claims (PVCs) it should be noted that destroying the cluster via Terraform does not in turn delete any PVCs (as they were created by the Kubernetes service and not under Terraform's purview). When spinning down an environment you will need to clean up these disks manually. Note this only applies to PVCs, any other disks are cleared up accordingly via a Terraform Destroy.

#### Example config (AWS)

An example config for testing an AWS environment (2K CNH) with Gitaly Sharded would be as follows:

```tf
module "gitlab_ref_arch_aws" {
  source = "../../modules/gitlab_ref_arch_aws"

  prefix = var.prefix
  ssh_public_key = file(var.ssh_public_key_file)

  default_disk_size = "30"

  # 10k - K8s
  webservice_node_pool_max_count = 3
  webservice_node_pool_min_count = 0
  webservice_node_pool_instance_type = "c5.2xlarge"

  sidekiq_node_pool_max_count = 2
  sidekiq_node_pool_min_count = 0
  sidekiq_node_pool_instance_type = "m5.xlarge"

  supporting_node_pool_max_count = 2
  supporting_node_pool_min_count = 1
  supporting_node_pool_instance_type = "m5.xlarge"

  # 2k
  gitaly_node_count = 1
  gitaly_instance_type = "m5.xlarge"
  gitaly_disk_size = "30"
  gitaly_disk_iops = 3000

  # 10k - AWS Services
  rds_postgres_instance_type = "m5.large"
  rds_postgres_password = "<password>"
  rds_postgres_multi_az = false
  rds_postgres_allocated_storage = "30"
  rds_postgres_storage_type = "gp3"

  elasticache_redis_node_count = 1
  elasticache_redis_instance_type = "m5.large"
  elasticache_redis_password = "<password>"
  elasticache_redis_engine_version = "7.0"

  opensearch_service_node_count = 1
  opensearch_service_instance_type = "m5.xlarge"
  opensearch_service_volume_size = "30"
  opensearch_service_volume_type = "gp3"
}
```

### GCP

The following options have default values set in the GCP Terraform module (default given in `[]` brackets) that can be adjusted to reduce costs:

#### GCE Disks

[Documentation](docs/environment_provision.md#configure-module-settings-environmenttf)

- `default_disk_size` [`100`] - Applies to all VMs and Kubernetes Node Pools except for the ones noted below:
  - `gitaly_disk_size` [`500`].
  - `opensearch_vm_disk_size` [`500`].
- `default_disk_type` [`pd-standard`] - [GCE Disk type](https://cloud.google.com/compute/docs/disks/performance) to apply to all VMs and Kubernetes Node Pools (except for the ones noted below). `pd-standard` is the "cheapest" disk type available but noted here for reference.
  - `gitaly_disk_type` [`pd-ssd`] - Can be switched out to a cheaper type such as `pd-balanced` or `pd-standard` if performance isn't a concern. 
  - `opensearch_vm_disk_type` [`pd-ssd`] - Can be switched out to a cheaper type such as `pd-balanced` or `pd-standard` if performance isn't a concern. 

Note that [Disk IOPS is calculated by VM CPU count and disk size](https://cloud.google.com/compute/docs/disks/performance#iops_limits_zonal_pd).

#### Cloud SQL

[Documentation](docs/environment_advanced_services.md#gcp-cloud-sql)

- `cloud_sql_postgres_disk_size` [`100`] - Disk size.
- `cloud_sql_postgres_disk_type` [`null`] - Disk type, default on GCP is `PD_SSD` so can be switched to `PD_HDD` to save costs.

#### Other notes

- Deploying Google Memorystore instances with a node count of 1 disables any standby replicas - This is sufficient for testing.
- Availability type for GCP Cloud SQL is `ZONAL` by default on GCP's end - This is the cheapest option.
- Cluster Autoscaler is enabled by default for all GKE clusters so setting a min count can lead to savings. Enabling [Cluster Autoscaler for AWS EKS clusters](docs/environment_advanced_hybrid.md#eks-cluster-autoscaling) can lead to savings if testing is expected to last a while.
- GKE clusters default to regional in the GCP provider. With Cluster Autoscaler this is fine as it will adjust the node pools accordingly to meet the total node count across zones. However it is technically a little cheaper to deploy a cluster in it's zonal form to reduce networking costs, which can be done by setting `gke_location` to a specific zone.
- When deploying GKE clusters with provisioned volume claims (PVCs) it should be noted that destroying the cluster via Terraform does not in turn delete any PVCs (as they were created by the Kubernetes service and not under Terraform's purview). When spinning down an environment you will need to clean up these disks manually. Note this only applies to PVCs, any other disks are cleared up accordingly via a Terraform Destroy.

#### Example config (GCP)

An example config for testing a GCP environment (2K CNH) would be as follows:

```tf
module "gitlab_ref_arch_gcp" {
  source = "../../modules/gitlab_ref_arch_gcp"

  prefix = var.prefix
  project = var.project

  # 10k Hybrid - k8s Node Pools
  webservice_node_pool_max_count = 3
  webservice_node_pool_min_count = 0
  webservice_node_pool_machine_type = "n1-standard-8"

  sidekiq_node_pool_max_count = 2
  sidekiq_node_pool_min_count = 0
  sidekiq_node_pool_machine_type = "n1-standard-4"

  supporting_node_pool_max_count = 2
  supporting_node_pool_min_count = 1
  supporting_node_pool_machine_type = "n1-standard-2"

  # 10k Hybrid - Compute VMs
  gitaly_node_count = 1
  gitaly_machine_type = "n1-standard-4"
  gitaly_disk_type = "pd-balanced"
  gitaly_disk_size = "30"

  opensearch_vm_node_count = 1
  opensearch_vm_machine_type = "n1-standard-4"
  opensearch_vm_disk_type = "pd-balanced"
  opensearch_vm_disk_size = "30"

  # 10k - Cloud SQL
  cloud_sql_postgres_machine_tier = "custom-2-8192"
  cloud_sql_postgres_root_password = "<password>"
  cloud_sql_postgres_disk_size = 30

  # 10k - Memorystore
  memorystore_redis_memory_size_gb = 4
  memorystore_redis_node_count = 1
}
```

### Azure

The following options have default values set in the Azure Terraform module (default given in `[]` brackets) that can be adjusted to reduce costs:

#### Azure Storage Disks

[Documentation](docs/environment_provision.md#configure-module-settings-environmenttf)

- `default_disk_size` [`100`] - Applies to all VMs except for the ones noted below:
  - `gitaly_disk_size` [`4095`] - Set high as this is required to meet the IOPS requirements. Can be reduced if performance is not a concern.
- `default_storage_account_type` [`Standard_LRS`] - [Azure Storage Disk type](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine#storage_account_type) to apply to all VMs (except for the ones noted below). `Standard_LRS` is the "cheapest" disk type available but noted here for reference.
  - `gitaly_storage_account_type` [`Premium_LRS`] - Can be switched out to a cheaper type such as `Standard_LRS` or `StandardSSD_LRS` if performance isn't a concern. 

Note that [Disk IOPS is calculated by VM CPU count and disk size](https://learn.microsoft.com/en-us/azure/virtual-machines/disks-types#premium-ssd-size).

#### Example config (Azure)

An example config for testing an Azure environment (2K CNH) would be as follows:

```tf
module "gitlab_ref_arch_azure" {
  source = "../../modules/gitlab_ref_arch_azure"

  prefix               = var.prefix
  location             = var.location
  storage_account_name = var.storage_account_name
  resource_group_name  = var.resource_group_name
  vm_admin_username    = var.vm_admin_username
  ssh_public_key       = file(var.ssh_public_key_file_path)
  external_ip_type     = "Standard"

  default_disk_size = "30"

  # 2k
  gitaly_node_count = 1
  gitaly_size = "Standard_D4s_v3"
  gitaly_disk_size = "30"
  gitaly_storage_account_type = "Standard_LRS"

  gitlab_rails_node_count = 2
  gitlab_rails_size = "Standard_F8s_v2"

  sidekiq_node_count = 1
  sidekiq_size = "Standard_D4s_v3"

  haproxy_external_node_count = 1
  haproxy_external_size = "Standard_F4s_v2"
  haproxy_external_external_ip_names = [var.external_ip_name]

  monitor_node_count = 1
  monitor_size = "Standard_F2s_v2"

  postgres_node_count = 1
  postgres_size = "Standard_D2s_v3"

  redis_node_count = 1
  redis_size = "Standard_D2s_v3"
}
```

## Further guidance or questions

To reiterate GET should only be used for testing when required to avoid incurring costs but if you require any additional guidance or have any questions please [reach out to the Self Managed Platform team](https://handbook.gitlab.com/handbook/engineering/infrastructure/test-platform/self-managed-excellence/#how-to-engage-with-us).
