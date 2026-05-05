# Advanced - Cloud Native Hybrid

- [GitLab Environment Toolkit - Quick Start Guide](environment_quick_start_guide.md)
- [GitLab Environment Toolkit - Preparing the environment](environment_prep.md)
- [GitLab Environment Toolkit - Provisioning the environment with Terraform](environment_provision.md)
- [GitLab Environment Toolkit - Configuring the environment with Ansible](environment_configure.md)
- [GitLab Environment Toolkit - Advanced - Custom Config / Tasks / Files, Data Disks, Advanced Search, Container Registry and more](environment_advanced.md)
- [**GitLab Environment Toolkit - Advanced - Cloud Native Hybrid**](environment_advanced_hybrid.md)
- [GitLab Environment Toolkit - Advanced - Component Cloud Services / Custom (Load Balancers, PostgreSQL, Redis)](environment_advanced_services.md)
- [GitLab Environment Toolkit - Advanced - SSL](environment_advanced_ssl.md)
- [GitLab Environment Toolkit - Advanced - Network Setup](environment_advanced_network.md)
- [GitLab Environment Toolkit - Advanced - Monitoring](environment_advanced_monitoring.md)
- [GitLab Environment Toolkit - Upgrades (Toolkit, Environment)](environment_upgrades.md)
- [GitLab Environment Toolkit - Considerations After Deployment - Backups, Security](environment_post_considerations.md)
- [GitLab Environment Toolkit - Geo](geo/README.md)
  - [GitLab Environment Toolkit - Geo - Provisioning the environment with Terraform](geo/geo_provision.md)
  - [GitLab Environment Toolkit - Geo - Configuring the environment with Ansible](geo/geo_configure.md)
  - [GitLab Environment Toolkit - Geo - Advanced](geo/geo_advanced.md)
- [GitLab Environment Toolkit - Troubleshooting](environment_troubleshooting.md)

The Toolkit can be used to deploy the [Cloud Native Hybrid Reference Architectures](https://docs.gitlab.com/administration/reference_architectures/#cloud-native-hybrid) where select components are deployed in Kubernetes via our [Helm charts](https://docs.gitlab.com/charts/) or [Operator](https://docs.gitlab.com/operator/) instead of static compute VMs.

On this page we'll detail how to deploy a Cloud Native Hybrid Reference Architecture with the Toolkit. **It's worth noting this guide is supplementary to the rest of the docs, and it will assume this throughout.**

> [!note]
> With Terraform, GET supports deploying Kubernetes clusters on AWS and GCP. With Ansible, it is possible to build Cloud Native Hybrid from other providers following [Custom Servers (On Prem)](environment_advanced.md#custom-servers-on-prem) documentation.

[TOC]

## Overview

A Cloud Native Hybrid Reference Architecture is where select GitLab components are deployed in Kubernetes via Helm Charts or Operator. This primarily includes running the equivalent of GitLab Rails and Sidekiq nodes, named Webservice and Sidekiq respectively, along with some supporting services such as Shell and Registry.

## 1. Install Kubernetes Tools

For the Toolkit to be able to provision and configure Kubernetes clusters and Helm charts it requires additional applications to be installed and available on the PATH of the host machine as follows:

- `kubectl` - [Install guide](https://kubernetes.io/docs/tasks/tools/#kubectl)
- `helm` - [Install guide](https://helm.sh/docs/intro/install/)
- `gcloud` - [Install guide](https://cloud.google.com/sdk/install). (GCP only)
- `aws cli` - [Install guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) (AWS only)

Latest info on version requirements can be found in the [GitLab Charts docs](https://docs.gitlab.com/charts/installation/tools.html).

## 2. Provisioning the Kubernetes Cluster with Terraform

The Toolkit supports provisioning a Kubernetes cluster using Google Kubernetes Engine (GKE) on GCP or Elastic Kubernetes Service (EKS) on AWS. Like a Linux Package (Omnibus) environment, the same [`environment.tf` file is used](environment_provision.md#configure-module-settings-environmenttf), with specific variables for each service. Refer to the sections below for each cloud provider respectively.

### Google Cloud Platform (GCP)

For Google Kubernetes Engine (GKE), the following main settings are available to configure a Kubernetes cluster and its associated Node Pools:

- `*_node_pool_max_count` / `*_node_pool_min_count` - The maximum and minimum amount of machines to be deployed in a node pool, managed via Cluster Autoscaling.
- `*_node_pool_count` - Static number of node pool machines to provision with no autoscaling. This should not be set if configuring `*_node_pool_max_count` / `*_node_pool_min_count`.
- `*_node_pool_machine_type` - The [GCP Machine Type](https://cloud.google.com/compute/docs/machine-types) (size) for each machine in the node pool.
- `*_node_pool_disk_size` - Root disk size in GB (optional)
- `*_node_pool_disk_kms_key` - KMS key for disk encryption (optional)

Below is an example `environment.tf` configuration for a [10k Cloud Native Hybrid](https://docs.gitlab.com/administration/reference_architectures/#cloud-native-hybrid) Reference Architecture, using [Cloud Provider services for Postgres and Redis](environment_advanced_services.md) and [created network stack](environment_advanced_network.md#created-gcp):

```tf
module "gitlab_ref_arch_gcp" {
  source = "../../modules/gitlab_ref_arch_gcp"

  prefix = var.prefix
  project = var.project

  create_network = true

  # 10k Hybrid - k8s Node Pools
  webservice_node_pool_max_count    = 4
  webservice_node_pool_min_count    = 1
  webservice_node_pool_machine_type = "n1-highcpu-32"

  sidekiq_node_pool_max_count    = 4
  sidekiq_node_pool_min_count    = 0
  sidekiq_node_pool_machine_type = "n1-standard-4"

  supporting_node_pool_max_count    = 2
  supporting_node_pool_min_count    = 1
  supporting_node_pool_machine_type = "n1-standard-4"

  # Gitaly on Kubernetes - Uncomment to use instead of VMs
  # gitaly_node_pool_count = 0
  # gitaly_node_pool_machine_type = "n1-standard-16"

  # 10k Hybrid - Compute VMs
  gitaly_node_count = 3
  gitaly_machine_type = "n1-standard-16"

  # 10k Hybrid - Cloud SQL & Memorystore
  cloud_sql_postgres_machine_tier = "custom-8-30720"
  cloud_sql_postgres_root_password = <PASSWORD>
  cloud_sql_postgres_version = "POSTGRES_17"
  cloud_sql_postgres_params = {
    "max_connections" = "3000"
  }

  memorystore_redis_cache_memory_size_gb = 16
  memorystore_redis_cache_node_count = 1
  memorystore_redis_cache_version = "REDIS_7_0"

  memorystore_redis_persistent_memory_size_gb = 16
  memorystore_redis_persistent_node_count = 1
  memorystore_redis_persistent_version = "REDIS_7_0"
}

output "gitlab_ref_arch_gcp" {
  value = module.gitlab_ref_arch_gcp
}
```

> [!note]
> With default settings, GKE will provision a Regional cluster that can't be changed after creation. Refer to [GKE Cluster Availability Type (Regional, Zonal and Autoscaling)](#gke-cluster-availability-type-regional-zonal-and-autoscaling) for more information.

In addition to the above, there are optional settings that can further configure the GKE setup:

- `gke_release_channel` - Set the [GKE release channel](https://cloud.google.com/kubernetes-engine/docs/concepts/release-channels) to control how fast the cluster updates to new Kubernetes releases. Default is `STABLE`.
- `gke_deletion_protection` - Configures [deletion protection](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster#deletion_protection) in Terraform. Default is `false`.
- `gke_datapath_provider` - Configures Dataplane type for the GKE cluster. Set to `ADVANCED_DATAPATH` to enable [Dataplane v2](https://cloud.google.com/kubernetes-engine/docs/concepts/dataplane-v2) on new GKE clusters. If left unset, the GKE default legacy dataplane will be used. Optional, default is `null`.

#### GKE Cluster Availability Type (Regional, Zonal and Autoscaling)

GKE has several options available when it comes to a [Cluster's availability type](https://cloud.google.com/kubernetes-engine/docs/concepts/types-of-clusters#availability). This covers both the control plane and the node pools themselves. There are two options available as follows:

- Regional - Control plane has replicas spread across a region's zones. Node pools are also configured to spread out nodes between the zones unless configured otherwise.
- Zonal - Control plane has no replicas and is deployed to a single zone. Node pools are also configured to only be deployed in that zone unless configured otherwise (which is known as a Multi-zonal cluster).

Before selecting an availability type you should be aware of the following:

- The Toolkit defaults to whatever the Terraform GCP provider selects, which was historically Zonal. [In `5.x` GCP changed this behaviour to now be regional](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/version_5_upgrade#changes-to-how-default-location-region-and-zone-values-are-obtained-for-resources) for _new_ Clusters.
- Attempting to change the availability type of existing clusters will trigger a full rebuild in GKE. As such, the Toolkit will ignore any attempts as a failsafe and such operations should be performed separately.
- [Due to the nature of how GKE spreads its node pools across zones](https://cloud.google.com/kubernetes-engine/docs/concepts/cluster-autoscaler#minimum_and_maximum_node_pool_size), Cluster Autoscaling is always enabled by default. This allows GKE to correct manage node pool count across multiple zones instead of deploying the same count per zone individually. For Clusters deployed with the single `*_node_pool_count` setting the minimum and maximum values are set the same accordingly to achieve the desired effect.

The following settings are available to configure the availability type of new clusters:

- `gke_location` - Set the location of the cluster (region or zone). If a region is selected the Cluster will be set as Regional with control plan and node pool resources per zone. If set to a zone, the cluster will be Zonal with all resources being placed in that zone. This variable only applies for new clusters as attempting to change will trigger a full rebuild of the whole cluster. If left unset, a Regional cluster will be provisioned in the [`region` configured for the Terraform GKE provider](environment_provision.md#configure-variables-variablestf). Optional.
- `gke_zones` - A list of Zone names inside the target region that Node Pools will be spread across. This is only recommended for use in advanced scenarios such as a Multi-Zonal cluster or overriding a Regional cluster's defaults. This will override what's given in the `zones` variable to allow for additional flexibility. If unset it will follow the former. Default is the same as `zones` (`null`). Optional.

#### GKE Private Cluster options

The Toolkit allows for you to configure a [Private cluster](https://cloud.google.com/kubernetes-engine/docs/concepts/private-cluster-concept) in GKE where Nodes, Pods and Services rely only on internal IP addresses, but external access can still be configured via ingress.

Private clusters can be configured in Terraform  as follows in your [`environment.tf`](environment_provision.md#configure-module-settings-environmenttf) file:

- `gke_enable_private_nodes` - Flag to configure the enabling of a Private cluster. Optional, default is `false`.
- `gke_enable_private_endpoint` - Flag to configure if **only** a Private endpoint is enabled for the Private cluster. If `false` then both a Public and Private endpoint are enabled. Optional, default is `false`.
- `gke_master_ipv4_cidr_block` - The CIDR block to be used by the Private Cluster for its internal network. The block must be a `/28` subnet and must not overlap with any other ranges in use within the cluster's network. Optional, default is `10.87.0.0/28`.

> [!note]
> It's not possible to convert an existing GKE cluster to be Private. Attempting to do this will trigger a full recreation of the GKE Cluster.

> [!note]
> When `gke_enable_private_endpoint` is enabled, GCP requires the `master_authorized_networks_config` setting to be enabled to block external access to the cluster's control plane. By default, only cluster node IPs will be allowed, though you can configure additional private network access. See [GKE Authorized Network config](#gke-authorized-network-config) for more information.

#### GKE Authorized Network config

It's possible to configure access to the cluster endpoints via the [`master_authorized_networks_config` setting](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster#master_authorized_networks_config) depending on the type of cluster:

- Public - Setting is disabled by default. Can be enabled to only allow access from configured CIDR blocks.
- Private - Setting is disabled by default except when Private endpoint only is configured, where it is then enabled as required to block all access (except Cluster node IPs) but can be extended to other internal network addresses.

The enabling and disabling of this setting is subject to the above and within those rules can be controlled via the following setting:

- `gke_master_authorized_networks_config_cidr_blocks` - Limit endpoint access to given CIDR blocks. For a public cluster this would be external public IP ranges. For a private cluster this would be valid internal IP ranges. Optional, default is `[]`.

For more information refer to the [GCP documentation](https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters).

#### GKE Workload Identity

> [!note]
> GKE Workload Identity is only supported with Charts installations from GitLab `17.0`.

[GKE Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity) can optionally be configured with the Toolkit. This is to allow deployments to authenticate directly via their own [Service Accounts](https://cloud.google.com/iam/docs/service-accounts#user-managed_service_accounts) to GCP services instead of using node accounts as a further security best practice.

Enabling Workload Identity will instruct the Toolkit to not only enable that option on the Cluster but to also create all the required GCP Service Accounts for the nodes and specific workloads respectively. This can be done in Terraform via the following setting in your [`environment.tf`](environment_provision.md#configure-module-settings-environmenttf) file:

- `gke_enable_workload_identity` - Enable [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/concepts/workload-identity) in the GKE cluster to deployments to authenticate directly via their own service accounts. Optional, default is `false`.

> [!important]
> To complete the Workload Identity setup, additional Ansible configuration is required. Refer to the [section](#google-cloud-platform-gcp-1) for more information.

##### GitLab Chart Namespace

In Kubernetes, namespaces allow for separating deployments within a cluster. This Toolkit typically manages this for you via Ansible for GitLab components by using the `default` namespace, but this is also configurable via the `gitlab_cloud_native_release_namespace` variable in Ansible.

However, if using GKE Workload Identity, Terraform also needs to be aware of the namespace for GitLab to set up the accounts to match correctly via the `gke_gitlab_cloud_native_namespace` variable.

As such, if you do choose to change the namespace for GitLab components you should change both the `gke_gitlab_cloud_native_namespace` and `gitlab_cloud_native_release_namespace` variables to match in both Terraform and Ansible respectively.

#### GKE Toolbox Backups - Service Account Key (<`17.0`)

With a Cloud Native Hybrid environment, [GitLab backups are taken via the Toolbox chart](https://docs.gitlab.com/charts/backup-restore/) that in turn will save backups to a selected Object Storage Bucket.

> [!note]
> For GitLab version `17.0` and higher, [Application Default Credentials](https://docs.gitlab.com/charts/advanced/external-object-storage/#backups) are used by default and no further configuration will be required.

For GitLab versions lower than `17.0`, an additional step is required to configure this correctly as the Charts require [the key of a Service Account](https://cloud.google.com/iam/docs/keys-create-delete) with the correct permissions to be given for the Toolbox to use at this time.

The Service Account requires the `roles/storage.objectAdmin` role to be given for each of the Object Storage Buckets to be used. The Toolkit creates a role for this purpose already with the suffix `-gke-supporting` so creating the account is not required. However, as Service Account keys are sensitive credential files the Toolkit doesn't generate the key specifically. As such, one manual step that is required in this scenario is to [generate a key](https://cloud.google.com/iam/docs/keys-create-delete) for this account and pass it accordingly to Ansible.

There are two options available to pass the key to Ansible to be subsequently configured, either by passing the JSON string directly or the location of the keyfile on the disk of the Ansible host. For both approaches this is configured in your [Environment config file](environment_configure.md#environment-config-varsyml) (`vars.yml`) as follows:

- `gcp_backups_service_account_key_json` - Full JSON contents of a GCP Service Account key to be used by the Charts Toolbox pod for performing Backups. The Service Account must have the `roles/storage.objectAdmin` role attached for each Object Storage bucket GitLab uses. If not set, backups will be disabled on the environment. Should not be used in conjunction with `gcp_backups_service_account_key_file`. Optional, default is `''`.
- `gcp_backups_service_account_key_file` - Full file path to a GCP Service Account key file on the host running Ansible to be used by the Charts Toolbox pod for performing Backups. The Service Account must have the `roles/storage.objectAdmin` role attached for each Object Storage bucket GitLab uses. If not set, backups will be disabled on the environment. Should not be used in conjunction with `gcp_backups_service_account_key_json`. Optional, default is `''`.

Note that you can also create a separate Service Account and key if desired as long as it has the correct permissions as given above.

#### Encryption

[GCP by default encrypts storage with service provided encryption keys](https://cloud.google.com/docs/security/encryption/default-encryption#googles_default_encryption) across all services.

##### GKE Disk Encryption (CMEK)

The Toolkit allows for you to configure GKE Node Pool disk encryption with [Customer-managed encryption keys (CMEK)](https://cloud.google.com/kms/docs/cmek) instead of the service defaults.

> [!note]
> Refer to the main [Customer managed encryption keys (CMEK) (GCP)](environment_provision.md#customer-managed-encryption-keys-cmek-gcp) section for more information on key requirements and setup.

This can be configured in Terraform via the [module's environment config file](environment_provision.md#configure-module-settings-environmenttf) with the following variables:

- `gke_default_disk_kms_key` - The GCP Key resource name for [CMEK storage encryption](environment_provision.md#customer-managed-encryption-keys-cmek-gcp). If not set Google provided keys will be used instead. Optional, default is `null`.
  - `*_node_pool_disk_kms_key` - The GCP Key resource name to use for specific GKE Node Pools. Will override `gke_default_disk_kms_key` if specified. Default is `null`.
    - Available component options: `webservice`, `sidekiq`, `supporting`.

##### GKE Secrets Envelope Encryption (CMEK)

As an additional security layer for Kubernetes secrets, which are already encrypted on disk automatically, you can optionally enable [envelope encryption of Kubernetes secrets in GKE](https://cloud.google.com/kubernetes-engine/docs/how-to/encrypting-secrets#envelope_encryption) with your own [Customer-managed encryption keys (CMEK)](https://cloud.google.com/kms/docs/cmek). This is also known as Application-layer secrets encryption or Database encryption in GKE.

This feature requires a [Cloud KMS key to be created separately](https://cloud.google.com/kubernetes-engine/docs/how-to/encrypting-secrets#creating-key). Once created, the feature can be enabled via the following variable in your [`environment.tf`](environment_provision.md#configure-module-settings-environmenttf) file:

- `gke_database_encryption_key_name` - The resource name for an existing [Cloud KMS key](https://cloud.google.com/kubernetes-engine/docs/how-to/encrypting-secrets#creating-key) to be used to envelope encrypt Kubernetes secrets. The name must be the full resource name and should be created in the correct region for a Zonal cluster as well as have the required permissions as detailed in the documentation. Optional, default is `null`.
  > [!note]
  > The name must be given in its [full resource ID format](https://cloud.google.com/kms/docs/resource-hierarchy) (`projects/<project-id>/locations/<location>/keyRings/<keyring>/cryptoKeys/<key>`)

### Amazon Web Services (AWS)

For AWS Elastic Kubernetes Service (EKS), the following main settings are available to configure a Kubernetes cluster and its associated Node Groups:

- `*_node_pool_max_count` / `*_node_pool_min_count` - Maximum and minimum machines for cluster autoscaling
  - `*_node_pool_count` - Static machine count with no autoscaling (alternative to min/max settings)
- `*_node_pool_instance_type` - The [AWS Instance Type](https://aws.amazon.com/ec2/instance-types/) for each machine
  > [!tip]
  > ARM-based instances require corresponding ARM AMI configuration, see [Optimized AMI Type](#optimized-ami-type-default).
- `*_node_pool_disk_size` - Root disk size in GB (optional)
- `*_node_pool_disk_kms_key_arn` - KMS key for disk encryption (optional)
- `*_node_pool_max_unavailable` - Maximum machines [unavailable](https://docs.aws.amazon.com/eks/latest/APIReference/API_NodegroupUpdateConfig.html) during updates (optional, defaults to 1)

Below is an example `environment.tf` configuration for a [10k Cloud Native Hybrid](https://docs.gitlab.com/administration/reference_architectures/#cloud-native-hybrid) Reference Architecture, using [Cloud Provider services for Postgres and Redis](environment_advanced_services.md) and [created network stack](environment_advanced_network.md#created-aws):

```tf
module "gitlab_ref_arch_aws" {
  source = "../../modules/gitlab_ref_arch_aws"

  prefix = var.prefix
  ssh_public_key = file(var.ssh_public_key_file)

  create_network = true

  # 10k Hybrid - k8s Node Pools
  webservice_node_pool_max_count = 4
  webservice_node_pool_min_count = 1
  webservice_node_pool_instance_type = "c5.9xlarge"

  sidekiq_node_pool_max_count = 4
  sidekiq_node_pool_min_count = 0
  sidekiq_node_pool_instance_type = "m5.xlarge"

  supporting_node_pool_max_count = 3
  supporting_node_pool_min_count = 1
  supporting_node_pool_instance_type = "m5.xlarge"

  # Gitaly on Kubernetes - Uncomment to use instead of VMs
  # gitaly_node_pool_count = 3
  # gitaly_node_pool_instance_type = "m5.4xlarge"
  # gitaly_node_pool_az_distribution = "per-az"  # Recommended for stateful workloads

  # 10k Hybrid - Compute VMs
  gitaly_node_count = 3
  gitaly_instance_type = "m5.4xlarge"

  # 10k Hybrid - AWS RDS & ElastiCache
  rds_postgres_instance_type = "m5.2xlarge"
  rds_postgres_password = <PASSWORD>
  rds_postgres_version = "17"

  elasticache_redis_cache_node_count = 1
  elasticache_redis_cache_instance_type = "m5.xlarge"
  elasticache_redis_cache_password = <PASSWORD>
  elasticache_redis_cache_engine_version = "7.0"

  elasticache_redis_persistent_node_count = 1
  elasticache_redis_persistent_instance_type = "m5.xlarge"
  elasticache_redis_persistent_password = <PASSWORD>
  elasticache_redis_persistent_engine_version = "7.0"
}

output "gitlab_ref_arch_aws" {
  value = module.gitlab_ref_arch_aws
}
```

#### EKS Version

By default, the Toolkit will leave it up to [AWS to manage the Kubernetes version for the cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster#version).

However, you can also specify the version as well as control upgrades if desired in Terraform via the following setting in your [`environment.tf`](environment_provision.md#configure-module-settings-environmenttf) file:

- `eks_version` - The Kubernetes version that the cluster should use if direct control is desired. Increase this value to perform an upgrade directly. Note that when set this also upgrades the Node Group VM's to use the latest AMI version for the cluster (see below for more info). Default is `null`.

> [!tip]
> It's recommended to regularly update your EKS version as the service will automatically upgrade clusters on versions that have reached the end of their support period, which in turn could create unintended clashes with the Terraform state. See [EKS Upgrade Policy](#eks-upgrade-policy) for more information.

##### EKS Upgrade Policy

By default, [AWS EKS Clusters will be upgraded automatically to the next version when the support period ends](https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html).

There are different support periods available as follows:

- Standard - 14 month window.
- Extended - 26 month window, with the last 12 months coming at an additional cost.

The default on AWS EKS is Extended. The Toolkit allows for you to change this as desired however via the following setting in your Terraform [`environment.tf`](environment_provision.md#configure-module-settings-environmenttf) file:

- `eks_upgrade_policy` - The [upgrade policy](https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html) for the EKS Cluster. Can be `EXTENDED` (service default) or `STANDARD`. Default is `null`.

> [!tip]
> It's recommended in either case to manage upgrades yourself before this behaviour is triggered to avoid any unexpected clashes with the Terraform state.

#### EKS Node Group Scaling

This section covers scaling considerations for EKS node groups including Cluster Autoscaler setup, stateful workload limitations in multi-AZ deployments, and Terraform limitations when adjusting node group sizes.

##### Cluster Autoscaling Setup

The provisioned EKS cluster and node groups are configured to support Cluster Autoscaling when setting node counts via the single (`*_node_pool_count`) or max / min values (`*_node_pool_max_count` / `*_node_pool_min_count`).

However, [Cluster Autoscaling won't actually be enabled until the component is deployed](https://docs.aws.amazon.com/eks/latest/userguide/autoscaling.html). This either needs to be done manually or can be done with the Toolkit via an additional setting in Ansible - `cloud_native_hybrid_cluster_autoscaler_setup`. Refer to [Advanced Configuration](#advanced-configuration) for more details.

##### Node Group Size Change Considerations

The Toolkit ignores `desired_size` in Terraform state [as recommended by AWS](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group#ignoring-changes-to-desired-size) to prevent conflicts with Cluster Autoscaler. This allows `desired_size` to drift from Terraform's tracked values, which means some size changes require [manually updating it in AWS](https://docs.aws.amazon.com/eks/latest/userguide/update-managed-node-group.html#mng-edit) first.

Increasing only `*_node_pool_max_count` when the current desired size is already above the minimum does not require any manual steps.

The following changes require updating `desired_size` in AWS beforehand:

- **Per-AZ node groups** - Any size change (always static)
- **Multi-AZ static node groups** - Any size change
- **Multi-AZ autoscaled node groups** - When increasing `*_node_pool_min_count` or decreasing `*_node_pool_max_count` past the current desired size

Update the desired size via the [AWS Console](https://docs.aws.amazon.com/eks/latest/userguide/update-managed-node-group.html#mng-edit) or the AWS CLI:

```sh
aws eks update-nodegroup-config \
  --cluster-name <prefix> \
  --nodegroup-name <node-group-name> \
  --scaling-config minSize=<current-min>,maxSize=<current-max>,desiredSize=<new-target>

aws eks wait nodegroup-active \
  --cluster-name <prefix> \
  --nodegroup-name <node-group-name>
```

Then run `terraform apply` as normal. For per-AZ node groups, repeat for each node group (one per availability zone).

> [!note]
> If you encounter `InvalidParameterException: Minimum capacity X can't be greater than desired size Y`, this indicates the desired size needs updating before Terraform can proceed. See [Troubleshooting](environment_troubleshooting.md#unable-to-adjust-node-group-sizes-due-to-minimum--desired-size-limitations-after-deployment) for more info.

##### Stateful Workloads and Multi-AZ Limitations

StatefulSet pods with EBS-backed PersistentVolumes can fail to deploy in multi-AZ EKS node groups due to two distinct issues:

- **EKS Managed Node Group Updates**: During [managed node group updates](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-update-behavior.html) (AMI upgrades, version changes), EKS temporarily scales up to [twice the number of Availability Zones](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-update-behavior.html#managed-node-update-scale-up) and then randomly terminates old nodes. This can leave stateful pods unable to schedule if their PersistentVolume is in a zone that no longer has nodes after the update completes.
- **Cluster Autoscaler Zone Targeting**: [Cluster Autoscaler cannot create nodes in specific zones](https://github.com/kubernetes/autoscaler/issues/6000) to match PersistentVolume locations. When scaling up, it may add nodes to zones that don't contain the required volumes, leaving pods stuck in `Pending` state with "volume node affinity conflict" errors.

As a solution to this, [AWS recommends per-AZ node groups](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html#managed-node-group-concepts) with static node counts to guarantee zone placement. The Toolkit supports this for **Gitaly and Supporting node groups only** (autoscaling is not supported with per-AZ distribution):

```tf
# Required: Per-AZ distribution with static sizing
gitaly_node_pool_count           = 3
gitaly_node_pool_az_distribution = "per-az"

supporting_node_pool_count           = 5
supporting_node_pool_az_distribution = "per-az"

# Do not set max_count - per-AZ requires static sizing
# Changing sizes may require a manual step, see "Node Group Size Change Considerations" above.
```

The Toolkit creates one node group per availability zone and distributes the total node count evenly (e.g. 5 nodes across 3 AZs → 2-2-1 distribution). This ensures stable zone placement during managed node group updates.

If this issue occurs on an existing deployment, see [Troubleshooting - Pods not deploying due to EBS Persistent Volume zone mismatch](environment_troubleshooting.md#pods-not-deploying-due-to-ebs-persistent-volume-zone-mismatch) for immediate resolution steps.

> [!warning]
> Switching to per-AZ distribution after initial deployment causes node group replacement. The Toolkit destroys the existing multi-AZ node group and creates new per-AZ node groups, triggering pod rescheduling. For stateful workloads like Gitaly, ensure backups are current and plan for downtime. Configure per-AZ distribution during initial deployment when possible.

#### EKS Node Group AMI Type and Versions

It's possible to configure what AMIs are to be used for the EKS Node Groups. There are numerous options available in this area that can interact in complex ways. The Toolkit aims to streamline this area and supports two options - Optimized AMI Type (Default) and Custom AMI ID. Refer to each section below for more information.

##### Optimized AMI Type (Default)

AWS provides numerous [optimized Amazon Linux AMIs](https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami.html). These are divided by Amazon Linux version, CPU architecture and EKS version. The Toolkit supports Amazon Linux AMIs as well as optional automatic upgrades where a new AMI version is released for the selected type.

This can be configured further in Terraform via the following settings in your [`environment.tf`](environment_provision.md#configure-module-settings-environmenttf) file:

- `eks_node_group_ami_type` - Optimized AMI type to use based on machine spec. Can be one of `AL2_x86_64`, `AL2_ARM_64`, `AL2023_x86_64_STANDARD` or `AL2023_ARM_64_STANDARD`. Will default to AWS x86 default for EKS version. Ignored if `eks_node_group_custom_ami_id` is set. Default is `AL2_x86_64` for EKS versions lower than `1.30` and `AL2023_x86_64_STANDARD` for versions equal to or higher.
  > [!tip]
  > If deploying on ARM machine types this setting will always need to be configured to the corresponding type.
- `eks_node_group_ami_release_version` - The [AMI release version](https://docs.aws.amazon.com/eks/latest/userguide/eks-linux-ami-versions.html) to use for the selected AMI type EKS. Can either be set to a specific version or just `latest` to enable automatic upgrades on subsequent Terraform runs. Defaults to `null`.
- `eks_node_group_ami_force_update_version` - If `eks_node_group_ami_release_version` is set to `latest` this additional variable can be set to `true` to force versions updates that ignores any pod draining blocks due to pod distribution budgets. Defaults to `null`.

##### Custom AMI ID

As an alternative it's also possible to set a specific custom AMI ID to be used for the Node Groups if desired.

> [!note]
> Creating such an image is outside the scope of this documentation, refer to the [official AWS documentation](https://docs.aws.amazon.com/eks/latest/userguide/eks-ami-build-scripts.html) for more information.

When deploying EKS Node Groups with a custom AMI ID a [`user data` script](https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html#launch-template-user-data) is required to be run on the nodes for them to join the cluster correctly. The Toolkit supports the `bootstrap` and `nodeadm` user data types and will configure this automatically for you as directed.

The above can be configured in Terraform via the following settings in your [`environment.tf`](environment_provision.md#configure-module-settings-environmenttf) file:

- `eks_node_group_custom_ami_id` - The AMI ID of the custom image to be used for the Node Groups. Defaults to `null`.
- `eks_node_group_custom_ami_userdata_type` - The type of `user data` script to configure. Can be one of `bootstrap` or `nodeadm`. Defaults to `bootstrap`.

#### EKS Addons

The Toolkit will enable several [EKS Addons](https://docs.aws.amazon.com/eks/latest/userguide/eks-add-ons.html) as required. EKS addons are AWS-managed components that provide essential functionality such as networking, DNS resolution, and storage integration. The Toolkit allows you to manage both addon versions and, where supported, custom configuration settings.

##### EKS Addon Versions

AWS regularly releases new versions for EKS addons outside the main EKS cluster version releases. The Toolkit provides variables to control addon versions and enables automatic upgrades on subsequent Terraform runs when desired.

It's recommended to manage these versions via the Toolkit to ensure Terraform maintains awareness of them in its state and avoid potential conflicts. The following considerations apply when managing addon versions:

- Setting the variables to `latest` will instruct Terraform to retrieve whatever the latest version is for each and upgrade them to it.
- Upgrades will only occur when Terraform is run.
- When using specific versions, ensure compatibility with your EKS cluster version.
- EKS cluster version upgrades may require corresponding addon and AMI version updates.

The following variables control addon versions in your [`environment.tf`](environment_provision.md#configure-module-settings-environmenttf) file:

- `eks_kube_proxy_version` - Version for the [EKS Kube Proxy addon](https://docs.aws.amazon.com/eks/latest/userguide/managing-kube-proxy.html). Accepts specific versions or `latest`. Defaults to `null`.
- `eks_coredns_version` - Version for the [EKS CoreDNS addon](https://docs.aws.amazon.com/eks/latest/userguide/managing-coredns.html). Accepts specific versions or `latest`. Defaults to `null`.
- `eks_vpc_cni_version` - Version for the [EKS VPC CNI addon](https://docs.aws.amazon.com/eks/latest/userguide/managing-vpc-cni.html). Accepts specific versions or `latest`. Defaults to `null`.
- `eks_ebs_csi_driver_version` - Version for the [EBS CSI Driver addon](https://docs.aws.amazon.com/eks/latest/userguide/managing-ebs-csi.html). Accepts specific versions or `latest`. Defaults to `null`.

##### EKS Addon Configuration

Beyond version management, some EKS addons support custom configuration to meet specific operational requirements, such as configuring [CoreDNS for scaling](https://docs.aws.amazon.com/eks/latest/userguide/coredns-autoscaling.html).

The following variables are available in your [`environment.tf`](environment_provision.md#configure-module-settings-environmenttf) file for configuring select addons:

- `eks_coredns_configuration_values` - Custom configuration map for the [CoreDNS addon](https://docs.aws.amazon.com/eks/latest/userguide/coredns-autoscaling.html). Defaults to `null`.
- `eks_vpc_cni_configuration_values` - Custom configuration map for the [VPC CNI addon](https://docs.aws.amazon.com/eks/latest/userguide/pod-networking-use-cases.html). Defaults to `null`.

#### EKS IAM Access Entries

When an EKS cluster is created, the IAM principal that was used to create the cluster is the only one configured that can access it. With the Toolkit this would be the IAM principal used with Terraform during creation.

Granting access to additional principals in the past required manually editing the `aws-auth` ConfigMap after creation. However, another method has been made available in [Access Entries](https://docs.aws.amazon.com/eks/latest/userguide/access-entries.html).

Access Entries allow for IAM principals to be configured natively via AWS EKS APIs and other interfaces, including Terraform. As such, the Toolkit enables this method by default and allows configuring standard access for specific IAM principals via the following variable in your Terraform [`environment.tf`](environment_provision.md#configure-module-settings-environmenttf) file:

- `eks_access_config_iam_arns` - A list of IAM principal ARNs to grant standard access to the created EKS cluster. Optional, default is `null`.
  > [!note]
  > For more advanced entries this can be configured separately, including the configuration of any [Access Entry Policy Associations](https://docs.aws.amazon.com/eks/latest/userguide/access-policies.html). Also note that the `aws-auth` ConfigMap option is also enabled on Toolkit created EKS clusters for backwards compatibility.

#### EKS IAM roles for service accounts (IRSA)

The Toolkit configures the AWS EKS cluster to use [IAM roles for service accounts (IRSA)](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html) for authenticating to AWS services as a security best practice.

While this should work out of the box for most setups there are a few scenarios when additional configuration may be required as detailed below.

##### GitLab Chart Namespace

In Kubernetes, namespaces allow for separating deployments within a cluster. This Toolkit typically manages this for you via Ansible for GitLab components by using the `default` namespace, but this is also configurable via the `gitlab_cloud_native_release_namespace` variable in Ansible.

However, since the Toolkit uses IRSA, Terraform also needs to be aware of the namespace for GitLab to set up the accounts to match correctly via the `eks_gitlab_cloud_native_namespace` variable.

As such, if you do choose to change the namespace for GitLab components you should change both the `eks_gitlab_cloud_native_namespace` and `gitlab_cloud_native_release_namespace` variables to match in both Terraform and Ansible respectively.

##### AWS IAM ARN Account and Partition

To configure IRSA, the Toolkit will look to pull the info it requires to correctly set the [IAM ARNs](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference-arns.html) for the GitLab Charts to use for authentication as a convenience via the [Ansible `aws_caller_info` module](https://docs.ansible.com/ansible/latest/collections/amazon/aws/aws_caller_info_module.html).

However, this depends on the AWS authentication method being used for Ansible and assumes that the account being used is in the same AWS Partition and Account as the environment being deployed. If this is not the case you will need to set the correct partition and account directly via the `aws_partition` and `aws_account` settings in your Ansible [Environment config file](environment_configure.md#environment-config-varsyml) (`vars.yml`). For example if the environment was deployed with the standard `aws` partition with the account ID `123456789` then you would configure the settings as follows:

```yml
all:
  vars:
    # Ansible Settings
    ansible_user: "<ssh_username>"
    ansible_ssh_private_key_file: "<private_ssh_key_path>"

    # Cloud Settings
    aws_partition: "aws"
    aws_account: 123456789

    [...]
```

#### EKS Endpoint Setup

[EKS Clusters have an endpoint](https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html) that is used in several ways including internode communication as well as giving access to tools such as the Toolkit and `kubectl`. This endpoint can be configured to be Public, Private or both.

The Toolkit will configure this endpoint to be both Public and Private by default. In this setup the Kubernetes nodes will default to the Private endpoint and keep their connections internal, but there's still an authenticated Public endpoint that the Toolkit uses to configure the cluster as well as be available for any debugging via `kubectl`.

In some cases you may prefer to restrict who can connect to the Public endpoint or disable it entirely. This is configurable in the Toolkit via Terraform with the following settings in your [`environment.tf`](environment_provision.md#configure-module-settings-environmenttf) file:

- `eks_endpoint_public_access` - Controls if the Public endpoint is enabled. Defaults to `true`.
  > [!important]
  > If this is disabled Ansible needs to be run within the same VPC as the Kubernetes cluster to ensure access.
- `eks_endpoint_public_access_cidr_blocks` - A list of CIDR blocks that are allowed access to the Public endpoint. Defaults to `['0.0.0.0/0']`.

#### EKS Control-Plane Logging

Amazon EKS control plane logging provides audit and diagnostic logs directly from the Amazon EKS control plane to CloudWatch Logs. You can select the exact log types you need by configuring the `eks_enabled_cluster_log_types` variable as an array of string values. Possible values are described in [Amazon EKS control plane logging documentation](https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html). Logs are sent as log streams to AWS CloudWatch.

> [!note]
> There are additional costs to enable this feature. Refer to the above docs for more info.

#### EKS Storage Encryption

The Toolkit will enable encryption by default for EKS Storage by enabling via service provided keys.
[AWS by default encrypts storage with service provided encryption keys](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingEncryption.html) across all services.

##### EKS Disk Encryption (CMEK)

The Toolkit allows for you to configure EKS Node Group disk encryption with [Customer-managed encryption keys (CMEK)](https://cloud.google.com/kms/docs/cmek) instead of the service defaults.

> [!note]
> Refer to the main [Customer managed encryption keys (CMEK) (AWS)](environment_provision.md#customer-managed-encryption-keys-cmek-aws) section for more information on key requirements and setup. Also note that any key used for EKS Node Group VM disks [requires additional policy to be set](https://docs.aws.amazon.com/autoscaling/ec2/userguide/key-policy-requirements-EBS-encryption.html) to allow the `AWSServiceRoleForAutoScaling` service-linked role access.

This can be configured in Terraform via the [module's environment config file](environment_provision.md#configure-module-settings-environmenttf) with the following variables:

- `eks_default_disk_kms_key_arn` - The AWS KMS key ARN for [CMEK storage encryption](environment_provision.md#customer-managed-encryption-keys-cmek-aws). If not set AWS provided keys will be used instead. Optional, default is `null`.
  - `*_node_pool_disk_kms_key_arn` - The AWS KMS key ARN to be used for specific EKS Node Group VM disks. Will override `eks_default_disk_kms_key_arn` if specified. Default is `null`.
    - Available component options: `webservice`, `sidekiq`, `supporting` and `gitaly`.

##### EKS Secrets Envelope Encryption (CMEK)

As an additional security layer for Kubernetes secrets, which are already encrypted on disk automatically, you can optionally enable [envelope encryption of Kubernetes secrets in EKS](https://aws.amazon.com/blogs/containers/using-eks-encryption-provider-support-for-defense-in-depth/) with your own KMS key.

Note however there are several limitations to this feature, such as manually having to encrypt any existing secrets, and it's recommended you review the [documentation](https://docs.aws.amazon.com/eks/latest/userguide/update-cluster.html#enable-kms) in full.

> [!warning]
> Enabling this feature is irreversible. Any changes to the key or attempting to disable the feature will require a full rebuild of the cluster.

Enabling the feature is controlled via the following variables:

- `eks_envelope_encryption` - Enables EKS Envelope Encryption. Optional, default is `false`.
- `eks_envelope_kms_key_arn` - The ARN for an existing [AWS KMS Key](https://aws.amazon.com/kms/) to be used to encrypt Kubernetes secrets. Note that the key should have the correct policy to allow access for the cluster's IAM role, [refer to the AWS docs for more info](https://docs.aws.amazon.com/eks/latest/userguide/update-cluster.html#enable-kms). If not provided, `default_kms_key_arn` or a Toolkit managed AWS KMS key will be used in that order. Optional, default is `null`.
  - Due to limitations with this feature, it's strongly recommended that you use your own KMS key with the correct policies that align with your security requirements.

#### Networking (AWS)

As detailed in the earlier [Configuring network setup (AWS)](environment_provision.md#configure-network-setup-aws) section the same networking options apply for Hybrid environments on AWS.

However, there are some additional networking considerations below that you should be aware of before building the environment.

##### Zones

For EKS a [Cluster is required to be spread across at least 2 Availability Zones](https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html). How this is handled depends on the network setup you've gone for:

- Default - Will attach to a number of default subnets. This is configurable via the `eks_default_subnet_count` variable that has a default of `2`.
- Create - Will create a number of subnets. This is configurable via the `subnet_pub_count` variable that has a default of `2`.
- Existing - When providing an existing network it's required that it has at least 2 subnets, each on a separate Zone.

#### Deprovisioning

Refer to the Toolkits [uninstallation documentation](environment_post_considerations.md#uninstalling) for correct steps to deprovision an AWS install of Cloud Native Hybrid.

## 3. Setting up authentication for the provisioned Kubernetes Cluster

Authenticating with Kubernetes is different compared to other services, and can be [considered a challenge](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/using_gke_with_terraform#interacting-with-kubernetes) in terms of automation.

In a nutshell authentication must be setup for the `kubectl` command on the machine running the Toolkit. The Toolkit requires the command to be authenticated, and the intended cluster selected as the current context in its `~/.kubeconfig` file.

The easiest way to do this is via the selected cloud providers tooling after the cluster has been provisioned:

- Google Cloud Platform (GCP) can be setup and selected via the `gcloud get-credentials` command. This differs depending on the availability type of the cluster provisioned:
  - Regional - `gcloud container clusters get-credentials <CLUSTER NAME> --project <GCP PROJECT NAME> --region <GCP REGION NAME>`
  - Zonal - `gcloud container clusters get-credentials <CLUSTER NAME> --project <GCP PROJECT NAME> --zone <GCP ZONE NAME>`.
  - Where `<CLUSTER NAME>` will be the same as the `prefix` variable set in Terraform.
- Amazon Web Services (AWS) can be setup and selected via the `aws update-kubeconfig` command, e.g. `aws eks --region <AWS REGION NAME> update-kubeconfig --name <CLUSTER NAME>`. Where `<CLUSTER NAME>` will be the same as the `prefix` variable set in Terraform.

As a convenience, the Toolkit can automatically run these commands for you in its configuration stage when the variable `kubeconfig_setup` is set to `true`, but it expects that you have configured authentication beforehand. This will be detailed more in the next section.

## 4. Configuring the Cloud Native deployment with Ansible

Configuring the Helm deployment requires additional settings in your [Environment config file](environment_configure.md#environment-config-varsyml) (`vars.yml`) for Kubernetes and Helm integration.

### General Settings

The following settings apply to any Cloud Provider:

- `cloud_native_hybrid_environment` - Enables Cloud Native Hybrid Reference Architecture configuration. **Required.**
- `kubeconfig_setup` - Automatically configures `.kubeconfig` for the provisioned cluster. **Recommended.**
- `external_url` - Environment URL with DNS A record (e.g., `http://gitlab.company.com`). **Required.**
  > [!note]
  > On AWS, this should resolve to one of the [Elastic IPs](environment_prep.md#4-create-static-external-ip-aws-elastic-ip-allocation) created during preparation.
- `gitlab_operator` - Use GitLab Operator instead of Charts (GitLab 17.6+ only). [Toolkit Beta](../TECHNICAL_DESIGN.md#beta-or-experimental-support) with [known limitations](https://docs.gitlab.com/operator/#known-issues). Optional, default is `false`.

### Chart Install Options

The Toolkit supports two methods for installing GitLab Helm Charts. Configure the installation method using the following settings:

**Helm Repository (default):**

Charts are retrieved and installed from a Helm repository server.

- `gitlab_charts_repo_url` - Chart repository URL. Default is `https://charts.gitlab.io/`
- `gitlab_charts_repo_name` - Repository name for Helm. Default is `gitlab`
- `gitlab_charts_gpg_key_file_path` - GPG key for [chart verification](https://docs.gitlab.com/charts/installation/chart-provenance.html)

**Direct Package:**

Charts are installed directly from a packaged `.tgz` file.

- `gitlab_charts_ref` - File path/URL to GitLab Charts `.tgz` package, accessible to the Ansible control node

**Node Selectors:**

By default, the Toolkit adds `workload` [node selectors](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector) to the Chart values. When using Toolkit provisioned infrastructure, the Kubernetes nodes will have appropriate `workload` labels to help distribute pods. When providing your own infrastructure, you may want to set your own node selectors, or turn them off entirely.

- `gitlab_charts_node_selector_enable` - Used to enable or disable `workload` node selectors across the chart. Default is set to `true`.
- `gitlab_charts_webservice_node_selector` - Used to specify `workload` node selector to use for Webservice pods. Default is set to `webservice`
- `gitlab_charts_sidekiq_node_selector` - Used to specify `workload` node selector to use for Sidekiq pods. Default is set to `sidekiq`
- `gitlab_charts_supporting_node_selector` - Used to specify `workload` node selector to use for supporting components. Default is set to `support`
- `gitlab_charts_gitaly_node_selector` - Used to specify `workload` node selector to use for Gitaly pods. Default is set to `gitaly`

### Google Cloud Platform (GCP)

For environments using GKE the following additional settings are available. Note that the external IP settings differ depending on whether NGINX Ingress or [Envoy Gateway](#ingress-configuration-envoy-gateway-and-nginx-ingress) (default from GitLab 19.0) is used:

- `gcp_ip_resource_names` - Comma separated list of the external IP resource name(s) in GCP to assign to the Envoy Gateway load balancer. Replaces `external_ip` when using Envoy Gateway. **Required (Envoy Gateway, GCP).**
- `external_ip` - External IP the environment will run on. Required along with `external_url` for Cloud Native Hybrid setups when using NGINX Ingress. Not used with Envoy Gateway — use `gcp_ip_resource_names` instead. **Required (NGINX Ingress).**
- `gcp_gke_location` - Name of Region or Zone the GCP Kubernetes cluster is in, depending on if it's Regional or Zonal respectively. Only required for Cloud Native Hybrid installs when `kubeconfig_setup` is set to true.
- `gcp_gke_workload_identity_setup` - Sets up deployments to use [GKE Workload Identity](#gke-workload-identity) for authentication via Service Account annotations. This must be set to `true` if the equivalent Terraform `gke_enable_workload_identity` setting has been enabled.
  - `gcp_service_account_prefix` - If `gcp_gke_workload_identity_setup` has been set to `true` and the [GCP Service Account prefix](environment_provision.md#service-account-prefix-gcp) was changed in Terraform from the default of `gl` this needs to also be set in Ansible to ensure the correct setup.

A full `vars.yml` file config example for GKE based on a [10k Cloud Native Hybrid Reference Architecture](https://docs.gitlab.com/administration/reference_architectures/#cloud-native-hybrid) is as follows:

```yml
all:
  vars:
    # Ansible Settings
    ansible_user: "<ssh_username>"
    ansible_ssh_private_key_file: "<private_ssh_key_path>"

    # Cloud Settings
    cloud_provider: "gcp"
    gcp_project: "<gcp_project_id>"
    gcp_gke_location: "<gcp_gke_region> / <gcp_gke_zone>"

    # General Settings
    prefix: "<environment_prefix>"
    external_url: "<external_url>"
    external_ip: "<external_ip>"
    gitlab_license_file: "<gitlab_license_file_path>"
    cloud_native_hybrid_environment: true
    kubeconfig_setup: true

    # Gitaly on Kubernetes
    # Webservice, Sidekiq and Gitaly pod sizings required in this setup
    # gitlab_charts_webservice_max_replicas: 20
    # gitlab_charts_sidekiq_max_replicas: 14
    # gitlab_charts_gitaly_setup: true
    # gitlab_charts_gitaly_requests_memory_gb: 51
    # gitlab_charts_gitaly_requests_cpu: 15
    # gitlab_charts_gitaly_storage_size: '300Gi'
    # gitlab_charts_gitaly_storage_names: ['default', 'storage2', 'storage3']

    # Component Settings
    patroni_remove_data_directory_on_rewind_failure: false
    patroni_remove_data_directory_on_diverged_timelines: false

    # Passwords / Secrets
    gitlab_root_password: '<gitlab_root_password>'
    postgres_password: '<postgres_password>'
    patroni_password: '<patroni_password>'
    consul_database_password: '<consul_database_password>'
    pgbouncer_password: '<pgbouncer_password>'
    redis_password: '<redis_password>'
    gitaly_token: '<gitaly_token>'
    praefect_external_token: '<praefect_external_token>'
    praefect_internal_token: '<praefect_internal_token>'
    praefect_postgres_password: '<praefect_postgres_password>'
```

### Amazon Web Services (AWS)

For environments using EKS the following additional settings are available:

- `aws_region` - Name of the region where the EKS cluster is located. Only required for Cloud Native Hybrid installs when `kubeconfig_setup` is set to true.
- `aws_allocation_ids` - A comma separated list of Elastic IP allocation IDs, that will be assigned to the AWS load balancer. **Required.**
  - With AWS, you **must have an [Elastic IP](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/docs/environment_prep.md#4-create-static-external-ip-aws-elastic-ip-allocation) for each subnet being used**. For example using a VPC with 3 subnets will require the creation of 3 Elastic IPs and their individual allocation IDs will need to be stored in this list.
- `cloud_native_hybrid_cluster_autoscaler_setup` - When `true` will deploy the [Cluster Autoscaler](https://docs.aws.amazon.com/eks/latest/userguide/autoscaling.html) onto the AWS EKS Kubernetes cluster to enable node autoscaling. Set to `false` by default.
- `cluster_autoscaler_charts_namespace` - Kubernetes namespace where the Cluster Autoscaler will be deployed. Since the Toolkit uses IRSA, Terraform also needs to be aware of the namespace to set up the accounts to match correctly via the `cluster_autoscaler_charts_namespace` variable. Set to `kube-system` by default.

A full `vars.yml` file config example for ELS based on a [10k Cloud Native Hybrid Reference Architecture](https://docs.gitlab.com/administration/reference_architectures/#cloud-native-hybrid) is as follows:

```yml
all:
  vars:
    # Ansible Settings
    ansible_user: "<ssh_username>"
    ansible_ssh_private_key_file: "<private_ssh_key_path>"

    # Cloud Settings
    cloud_provider: "aws"
    aws_region: "<aws_region_name>"
    aws_allocation_ids: "<aws_allocation_id1>,<aws_allocation_id2>"

    #General Settings
    prefix: "<environment_prefix>"
    external_url: "<external_url>"
    gitlab_license_file: "<gitlab_license_file_path>"
    cloud_native_hybrid_environment: true
    kubeconfig_setup: true

    # Gitaly on Kubernetes
    # Webservice, Sidekiq and Gitaly pod sizings required in this setup
    # gitlab_charts_webservice_max_replicas: 20
    # gitlab_charts_sidekiq_max_replicas: 14
    # gitlab_charts_gitaly_setup: true
    # gitlab_charts_gitaly_requests_memory_gb: 51
    # gitlab_charts_gitaly_requests_cpu: 15
    # gitlab_charts_gitaly_storage_size: '300Gi'
    # gitlab_charts_gitaly_storage_names: ['default', 'storage2', 'storage3']

    # Component Settings
    patroni_remove_data_directory_on_rewind_failure: false
    patroni_remove_data_directory_on_diverged_timelines: false

    # Passwords / Secrets
    gitlab_root_password: '<gitlab_root_password>'
    postgres_password: '<postgres_password>'
    patroni_password: '<patroni_password>'
    consul_database_password: '<consul_database_password>'
    pgbouncer_password: '<pgbouncer_password>'
    redis_password: '<redis_password>'
    gitaly_token: '<gitaly_token>'
    praefect_external_token: '<praefect_external_token>'
    praefect_internal_token: '<praefect_internal_token>'
    praefect_postgres_password: '<praefect_postgres_password>'
```

### Advanced Configuration

The Toolkit provides several other settings that can customize a Cloud Native Hybrid setup further as follows:

- `gitlab_version` - Sets the GitLab version to be installed. The Toolkit finds and selects the equivalent Helm Chart version if configured. This should be set to the full semantic version, e.g. `14.0.0`. If left unset the Toolkit will look to install the latest version. Optional, default is `''`.
- `gitlab_cloud_native_release_namespace`: Kubernetes namespace the Helm chart will be deployed to. This should only be changed when the namespace is known to be different from the typical default of `default`. Set to `default` by default.

**Webservice Configuration:**

- `gitlab_charts_webservice_requests_memory_gb`: Memory [request](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits) for each Webservice pod in GB. Set to `5` by default.
- `gitlab_charts_webservice_limits_memory_gb`: Memory [limits](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits) for each Webservice pod in GB. Set to `7` by default.
- `gitlab_charts_webservice_requests_cpu`: CPU [request](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits) for Webservice pods in cores. Changing this will affect the number of Puma workers by default unless `gitlab_charts_webservice_worker_processes` is specified and should only be done for specific reasons. Set to `4` by default.
- `gitlab_charts_webservice_worker_processes`: Number of Puma worker processes per Webservice pod. By default, this will be automatically calculated based on CPU request as specified by `gitlab_charts_webservice_requests_cpu` (1 worker per full CPU, with a minimum of 1). For example, if you set `gitlab_charts_webservice_requests_cpu` to `3500m`, you'll get 3 workers. You can explicitly set this value to override the calculation. Defaults to calculated value.
- `gitlab_charts_webservice_min_replicas_scaler`: Sets the scalar value (`0.0` - `1.0`) to scale minimum pod replicas against the automatically calculated maximum value. If pod count is overridden directly by `gitlab_charts_webservice_min_replicas` this value will have no effect. Set to `0.75` by default.
- `gitlab_charts_webservice_max_unavailable_scaler`: Sets the scalar value (`0.0` - `1.0`) to scale maximum unavailable pod replicas against the automatically calculated maximum value. If pod count is overridden directly by `gitlab_charts_webservice_max_unavailable` this value will have no effect. Set to `0.1` by default.
- `gitlab_charts_webservice_max_replicas`: Override for the number of max Webservice replicas instead of them being automatically calculated. Defaults to `''`.
- `gitlab_charts_webservice_min_replicas`: Override for the number of min Webservice replicas instead of them being automatically calculated. Defaults to `''`.
- `gitlab_charts_webservice_max_unavailable`: Override for the number of max Webservice replicas that can be unavailable at any time instead of being automatically calculated. Defaults to `''`.

**Sidekiq Configuration:**

- `gitlab_charts_sidekiq_requests_memory_gb`: Memory [request](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits) for each Sidekiq pod in GB. Set to `2` by default.
- `gitlab_charts_sidekiq_limits_memory_gb`: Memory [limits](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits) for each Sidekiq pod in GB. Set to `4` by default.
- `gitlab_charts_sidekiq_requests_cpu`: CPU [request](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits) for Sidekiq pods in cores. Changing this will affect pod sizing and should only be done for specific reasons. Set to `1` by default.
- `gitlab_charts_sidekiq_min_replicas_scaler`: Sets the scalar value (`0.0` - `1.0`) to scale minimum pod replicas against the automatically calculated maximum value. If pod count is overridden directly by `gitlab_charts_sidekiq_min_replicas` this value will have no effect. Set to `0.75` by default.
- `gitlab_charts_sidekiq_max_unavailable_scaler`: Sets the scalar value (`0.0` - `1.0`) to scale maximum unavailable pod replicas against the automatically calculated maximum value. If pod count is overridden directly by `gitlab_charts_sidekiq_max_unavailable` this value will have no effect. Set to `0.1` by default.
- `gitlab_charts_sidekiq_max_replicas`: Override for the number of max Sidekiq replicas instead of them being automatically calculated. Defaults to `''`.
- `gitlab_charts_sidekiq_min_replicas`: Override for the number of min Sidekiq replicas instead of them being automatically calculated. Defaults to `''`.
- `gitlab_charts_sidekiq_max_unavailable`: Override for the number of max Sidekiq replicas that can be unavailable at any time instead of being automatically calculated. Defaults to `''`.

**Gitaly Configuration:**

- `gitlab_charts_gitaly_setup` - Enables running Gitaly in Kubernetes instead of VMs. Defaults to `false`.
- `gitlab_charts_gitaly_requests_memory_gb` - Memory [request](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits) for each Gitaly pod in GB. Default is `''`.
- `gitlab_charts_gitaly_limits_memory_gb` - Memory [limits](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits) for each Gitaly pod in GB. By default, this matches `gitlab_charts_gitaly_requests_memory_gb` to ensure Guaranteed QoS. Changing this should only be done in advanced scenarios.
- `gitlab_charts_gitaly_requests_cpu` - CPU [request](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits) for Gitaly pods. Default is `''`.
- `gitlab_charts_gitaly_limits_cpu` - CPU [limits](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits) for Gitaly pods. By default, this matches `gitlab_charts_gitaly_requests_cpu` to ensure Guaranteed QoS. Changing this should only be done in advanced scenarios.
- `gitlab_charts_gitaly_storage_size` - The size of the [Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) for Gitaly data storage in [SI or Binary notation](https://kubernetes.io/docs/reference/glossary/?all=true#term-quantity), e.g. `300Gi`. Default is `50Gi`.
- `gitlab_charts_gitaly_storage_class` - Custom [Storage Class](https://kubernetes.io/docs/concepts/storage/storage-classes/) for Gitaly persistent volumes. If unset, the Toolkit creates an appropriate storage class. See [Persistent Volume Configuration](#persistent-volume-configuration-storageclass) for details. Default is `''`.
- `gitlab_charts_gitaly_storage_names` - List of storage names to configure for Gitaly. Controls the number of pods deployed (one pod per storage). Default is `['default']`.

> [!important]
> When Gitaly in Kubernetes has been enabled, `gitlab_charts_webservice_max_replicas` and `gitlab_charts_sidekiq_max_replicas` must be explicitly set as automatic pod count calculations are not possible.

Once your config file is in place as desired you can proceed to [configure as normal](environment_configure.md#4-configure).

#### Ingress Configuration (Envoy Gateway and NGINX Ingress)

From GitLab 19.0, [Envoy Gateway](https://docs.gitlab.com/charts/advanced/gateway-api/) is the default ingress for all GitLab Helm chart deployments. Installs on earlier versions continue to use NGINX Ingress.

> [!important]
> Switching from NGINX Ingress to Envoy Gateway on an existing environment involves downtime.
> If you are upgrading an existing environment to GitLab 19.0, refer to the
> [Envoy Gateway migration guide](https://docs.gitlab.com/charts/installation/migration/envoy_gateway_migration/)
> in the GitLab Charts documentation before upgrading.

- `gitlab_charts_envoy_gateway_enable` - Set to `false` to skip installing the bundled Envoy Gateway controller and CRDs. Use this when your tooling manages the Envoy Gateway controller separately. Gateway API chart values are still configured. Defaults to `true`.
- `gitlab_charts_envoy_gateway_crd_repo_ref` - Reference to the Helm chart used to render the Gateway API and Envoy Gateway CRDs. Optional, default is `oci://docker.io/envoyproxy/gateway-crds-helm`.
- `gcp_ip_resource_names` - Comma separated list of the external IP resource name(s) in GCP to assign to the Envoy Gateway load balancer, e.g. `"gitlab-lb-ip-1, gitlab-lb-ip-2"`. **Required on GCP.**
- `gitlab_charts_nginx_ingress_enable` - Set to `true` to use NGINX Ingress instead of Envoy Gateway on any GitLab version. NGINX Ingress is supported as an opt-in path and will be removed in a future release. Defaults to `false`.

> [!note]
> Setting `gitlab_charts_envoy_gateway_enable` to `false` with `gitlab_charts_nginx_ingress_enable` left as `false` means GET will not configure ingress or Gateway API in any way. The chart defaults apply and you are fully responsible for ingress configuration. Use [Custom Config](environment_advanced.md#custom-config) to pass the required chart values, referring to the [GitLab Charts Gateway API documentation](https://docs.gitlab.com/charts/advanced/gateway-api/) for the available options.

#### Migrating Gitaly from VMs to Kubernetes

The Toolkit supports running VM-based Gitaly and Kubernetes-based Gitaly simultaneously to allow for migrations. When both the `gitaly` inventory group and `gitlab_charts_gitaly_setup: true` are configured together, the Helm values template renders both `external:` (VM) and `internal:` (Kubernetes) Gitaly stanzas, allowing GitLab to route to both during a migration.

Two constraints shape the migration approach. First, GitLab [does not allow duplicate storage names across external and internal Gitaly](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configure-gitaly-clients), so `gitlab_charts_gitaly_storage_names` must use non-conflicting names while VM Gitaly is still active (for example `['k8s-storage1', 'k8s-storage2']`). Second, GitLab [requires a storage named `default` to exist at all times](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#gitlab-requires-a-default-repository-storage). During the migration `default` remains on VM Gitaly and can only be reassigned to Kubernetes Gitaly once the VMs are removed.

> [!warning]
> **Take a full backup of your GitLab instance before starting this migration.** The cutover step permanently destroys VM infrastructure and cannot be undone. A backup is your only recovery option if something goes wrong. See [Backups](environment_post_considerations.md#backups) for guidance.

> [!important]
> **As a general rule for Gitaly on Kubernetes, never reorder or insert entries into `gitlab_charts_gitaly_storage_names`.** Each entry's position in the list maps directly to a Gitaly pod ordinal (`gitaly-0`, `gitaly-1`, and so on). Reordering or inserting entries causes existing pods to be assigned the wrong storage names, resulting in pods serving data under an incorrect name. **Always append new storage names to the end of the list.**

The migration process is as follows:

1. **Deploy Kubernetes Gitaly alongside VM Gitaly** - Enable `gitlab_charts_gitaly_setup: true` and set `gitlab_charts_gitaly_storage_names` to non-conflicting names (for example `['k8s-storage1']`). Keep the existing `gitaly` inventory group and `gitaly_node_count` in place. Run Terraform and Ansible as normal. GitLab will be configured with both VM and Kubernetes Gitaly storages available.

   > [!note]
   > Size the Gitaly node pool for your **final** storage count, not just the initial one. Each storage name in `gitlab_charts_gitaly_storage_names` schedules one pod, so adding `default` at cutover requires a free node to be available immediately. If the node pool has no spare capacity at that point, the new pod will remain pending until a node provisions, extending the maintenance window. The recommended approach is to configure the node pool for n nodes but start with n-1 storage names, leaving one node free to absorb the `default` pod at cutover.

1. **Migrate repositories off VM storages** - Use GitLab's [repository storage move options](https://docs.gitlab.com/administration/operations/moving_repositories/) to move **all** repositories from the VM storages (`default`, `storage1`, and so on) onto the Kubernetes storages (`k8s-storage1`, and so on). This can be done live without downtime. Set the VM storages to a weight of `0` in the [Admin area](https://docs.gitlab.com/administration/repository_storage_paths/#configure-where-new-repositories-are-stored) to prevent new repositories being created there during the migration.

   Before proceeding to cutover, confirm that no repositories remain on VM storages. You can verify this via the [repository storage Admin area](https://docs.gitlab.com/administration/repository_storage_paths/) or the [storage migrations API](https://docs.gitlab.com/api/project_repository_storage_moves/). Do not proceed until all moves have completed successfully.

1. **Cutover (maintenance window required)** - Once all repositories have been moved off VM storages, a short maintenance window is required. **This step is irreversible.** The VM Gitaly nodes will be permanently destroyed. The `default` storage name cannot exist on both VM and Kubernetes Gitaly simultaneously, so the following steps must be performed together and without delay:

   1. Enable [GitLab maintenance mode](https://docs.gitlab.com/administration/maintenance_mode/) to stop writes before making any infrastructure changes.
   1. Append `default` to `gitlab_charts_gitaly_storage_names`, keeping any existing entries in place:

      `['k8s-storage1', 'default']`

      Remove the `gitaly` inventory group and set `gitaly_node_count` (and `gitaly_node_pool_count` if applicable) to `0` in Terraform variables.
   1. Run Terraform to remove the VM Gitaly nodes.
   1. Run Ansible as soon as Terraform completes to apply the updated Helm configuration. This removes the external Gitaly stanza and creates a new pod (`gitaly-1`, corresponding to the second item in the storage names array) to serve the empty `default` storage.
   1. Disable maintenance mode once Ansible completes and GitLab is healthy.

   > [!note]
   > The new Kubernetes `default` pod starts with an empty disk. This is expected as all repositories should have been moved off VM `default` in step 2.

1. **Post-cutover** - Verify GitLab is healthy and all repositories are accessible.

#### Persistent Volume Configuration (StorageClass)

Stateful workloads in Kubernetes require [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) backed by [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/) to ensure data persists across pod restarts and cluster operations.

The available Storage Classes will vary depending on the Kubernetes service being used. For that reason, the Toolkit can be configured to use custom Storage Classes or create its [own](../ansible/roles/gitlab_charts/templates/storage_classes) when none have been configured per component:

- **AWS**: GP3-based storage class optimized for performance and cost
- **GCP**: Balanced persistent disk storage class for general workloads

To use custom Storage Classes that already exist in the cluster, set the following variables in the Ansible [`vars.yml`](environment_configure.md#environment-config-varsyml) file:

- `gitlab_charts_gitaly_storage_class` - Custom Storage Class for Gitaly persistent volumes
- `kube_prometheus_stack_charts_storage_class` - Custom Storage Class for monitoring data (when monitoring is enabled)

> [!note]
> Storage Class configuration can only be set during initial deployment. Changes require manual persistent volume operations or environment recreation.

### Kubernetes Secrets

The GitLab Charts utilize Kubernetes Secrets throughout for config such as [GitLab secrets](https://docs.gitlab.com/charts/installation/secrets.html), passwords, certificates and more.

The Toolkit in turn will [configure various secrets](../ansible/roles/gitlab_charts/tasks/secrets.yml) depending on the setup accordingly when deploying the Charts as part of a Cloud Native Hybrid environment, including:

- Password secrets - From Ansible password variables.
- Object Storage keys for authentication to GCP or AWS - Using IAM based mechanisms or Ansible variables.
- SSL certificate secrets as configured - From Ansible variables.
- Container Registry notification secrets as configured - From Ansible variables.

It's recommended to let the Toolkit manage the above secrets for you by configuring via the Ansible variables as noted as it not only sets up the secrets but the equivalent Charts config accordingly to consume said secrets. For any other secrets these can be configured as desired separately or via [Custom Kubernetes Secrets (via Custom Tasks)](#custom-kubernetes-secrets-via-custom-tasks).

Additionally, depending on the setup, the following secrets may be copied from Linux package (Omnibus) VM backends if present to ensure consistency:

- [GitLab Rails](https://docs.gitlab.com/charts/installation/secrets.html#gitlab-rails-secret) (as `gitlab-rails-secrets`) and [GitLab Shell](https://docs.gitlab.com/charts/installation/secrets.html#gitlab-shell-secret) secrets (as `gitlab-shell-token`) - Propagated from Linux package (Omnibus) backends if available to ensure synchronisation as required.
  - > [!note]
    > This includes any custom values for these secrets passed in via [Custom GitLab Secrets](environment_advanced.md#custom-gitlab-secrets---linux-package-omnibus) to Linux package (Omnibus) backends when present.

#### Custom Kubernetes Secrets (via Custom Tasks)

It's possible for you to set your own custom Kubernetes secrets as desired via a tasks hook.

> [!caution]
> **This is an advanced feature, and it must be used with caution**. Adding custom GitLab secrets may lead to various unintended consequences or broken environments if not used carefully.

This can be used to set any Kubernetes secret, including any of the ones [noted above](#kubernetes-secrets), although this is generally not recommended as noted. If you choose to configure secrets directly in this manner you would also be expected to manage any dependents such as ensuring GitLab secrets are correctly synchronised on any backends as required as well as Charts config to consume said secrets.

Configuring secrets in this manner involves creating a list of Ansible tasks, such as [`kubernetes.core.k8s`](https://github.com/ansible-collections/kubernetes.core/blob/main/docs/kubernetes.core.k8s_module.rst), that it will run through accordingly. An example to configure a secret for GitLab Workhorse you could do so with the following task:

```yml
- name: Configure GitLab Workhorse secret
  kubernetes.core.k8s:
    state: present
    definition:
      kind: Secret
      type: Opaque
      metadata:
        name: "gitlab-gitlab-workhorse-secret"
        namespace: "{{ gitlab_cloud_native_release_namespace }}" # This should stay the same
      stringData:
        shared_secret: |
          <SECRET VALUE>
  diff: false
```

Note that the name for the GitLab Chart deployment, which it uses for default secret names, is `gitlab`,

The overall process for providing custom Kubernetes secrets for the Charts is done as follows:

1. Create a standard Ansible Tasks yaml file with the tasks you wish to run.
    - The file must be in a format that can be run in Ansible's [`include_tasks`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/include_tasks_module.html) module.
    - You can add the tag `custom_tasks` to your tasks if you wish to run the tasks in isolation.
1. By default, the Toolkit looks for Custom Tasks files in the [environment's](environment_configure.md#2-set-up-the-environments-inventory-and-config) `files/gitlab_tasks` folder path. E.G. `ansible/environments/<env_name>/files/gitlab_tasks/gitlab_charts_secrets.yml`. Save your file in this location with the same name.
    - If you wish to store your file in a different location or use a different name the full path that Ansible should use can be set via a variable for each different component e.g. `gitlab_charts_secrets_tasks_file`.

With the above done, the file will be run before the Cloud Native deployment to add the new secrets. Note that they will always take precedence over any secrets the Toolkit creates itself.

## Geo

More information on setting up Geo within GET can be found in our [GitLab Environment Toolkit - Advanced - Geo](geo/README.md) documentation.

## Monitoring

More information on setting up an optional Monitoring stack for Cloud Native Hybrid environments [GitLab Environment Toolkit - Advanced - Monitoring](environment_advanced_monitoring.md#cloud-native-hybrid-kube-prometheus-stack) documentation.

## Troubleshooting

Cloud Native Hybrid environments have quite a few moving parts, all of which could cause a failure.

Some common Troubleshooting steps to follow for these setups can be found on the [GitLab Environment Toolkit - Troubleshooting](environment_troubleshooting.md#cloud-native-hybrid) page.
