# Provisioning the environment with Terraform

- [GitLab Environment Toolkit - Quick Start Guide](environment_quick_start_guide.md)
- [GitLab Environment Toolkit - Preparing the environment](environment_prep.md)
- [**GitLab Environment Toolkit - Provisioning the environment with Terraform**](environment_provision.md)
- [GitLab Environment Toolkit - Configuring the environment with Ansible](environment_configure.md)
- [GitLab Environment Toolkit - Advanced - Custom Config / Tasks / Files, Data Disks, Advanced Search, Container Registry and more](environment_advanced.md)
- [GitLab Environment Toolkit - Advanced - Cloud Native Hybrid](environment_advanced_hybrid.md)
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

With [Terraform](https://developer.hashicorp.com/terraform), you can automatically provision machines and associated dependencies on a provider.

The Toolkit provides multiple curated [Terraform Modules](../terraform/modules) that will provision the machines for a GitLab environment as per the [Reference Architectures](https://docs.gitlab.com/ee/administration/reference_architectures/).

> [!important]
> A good working knowledge of Terraform and GitLab administration before proceeding is recommended. This documentation assumes this throughout.

[TOC]

## 1. Install Terraform

For the Toolkit Terraform `v1.12.0` or higher is required.

Terraform generally works best when all users for an environment are using the same major version due to its State. As such it's recommended that all users sync on the same version of Terraform when working against the same environment and any Terraform upgrades are done in unison.

### Install Terraform using `mise` or `asdf`

With the above considerations then we recommend installing Terraform with a Version Manager such as [`mise`](https://github.com/jdx/mise) or [`asdf`](https://asdf-vm.com/#/) (if supported on your machine(s)).

Installing Terraform with a version manager like this has several benefits:

- It's significantly easier to install and switch between multiple versions of Terraform once set up.
- The Terraform version can be specified in a `.tool-versions` file, version managers will look for and automatically switch to the version specified, this is useful when managing multiple environments where the Terraform version differs.

As an example, installing Terraform with `mise` is done as follows:

1. Install `mise` as per its [documentation](https://mise.jdx.dev/getting-started.html)
1. In the Toolkit directory, install the default version of Terraform by first adding its plugin and then installing:

    ```sh
    mise install terraform -y
    ```

  > [!note]
  > The version of Terraform installed is set in the [`.tool-versions` file](../.tool-versions). Other versions can be installed as required via `mise` - `mise install terraform <version> -y`

With the above completed Terraform should now be available on your command line. You can check this by running `terraform version`.

### Using Terraform via a Docker image

It is possible to use Terraform from a Docker image.

The [Toolkit's image](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/container_registry/2697240) comes with the default version of Terraform installed as defined in [`.tool-versions`](../.tool-versions) via the `mise` package manager. Additional Terraform versions can be installed via `mise` as [detailed earlier](#install-terraform-using-mise-or-asdf).

Follow the official [Docker installation instructions](https://docs.docker.com/engine/install/) to correctly install and run Docker.

## 2. Select Module Source

Before you start setting up the config you should select a Terraform Module source to use.

Terraform can retrieve Modules from various [sources](https://developer.hashicorp.com/terraform/language/modules/configuration). The Toolkit's Modules are available from Local paths, Git URL or this Project's Terraform Module Registry.

Below we detail each source and how to configure them:

> [!note]
> This documentation assumes the Local Path method is being used but any of these sources can be used as desired.

### Local Path

In this setup you have the Modules saved locally on disk, typically through a Git clone of this repo, and Terraform is configured to source them via an absolute or relative local path.

For example, to configure the `gitlab_ref_arch_gcp` module using a relative path that follows this repo's structure you would configure it follows:

```tf
module "gitlab_ref_arch_gcp" {
  source = "../../modules/gitlab_ref_arch_gcp"

  [...]
}
```

### Git URL

Terraform can also pull the Modules directly from this repo via a [Git URL](https://developer.hashicorp.com/terraform/language/block/module#git-repository).

For example, to configure the `gitlab_ref_arch_gcp` module to pull from the repo you would configure it follows:

```tf
module "gitlab_ref_arch_gcp" {
  source = "git::https://gitlab.com/gitlab-org/gitlab-environment-toolkit.git//modules/gitlab_ref_arch_gcp"

  [...]
}
```

### Terraform Module Registry

The Toolkit's Modules are also made available via this Project's [Terraform Module Registry](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/infrastructure_registry).

For example, to configure the `gitlab_ref_arch_gcp` module to pull from the registry you would configure it follows:

```tf
module "gitlab_ref_arch_gcp" {
  source = "gitlab.com/gitlab-org/gitlab-environment-toolkit/gitlab//modules/gitlab_ref_arch_gcp"
  version = ">= 3.0.0"

  [...]
}
```

Note the `version` setting here [can be changed as desired to any constraint](https://developer.hashicorp.com/terraform/language/expressions/version-constraints#version-constraint-syntax) that's `2.0.0` or greater.

## 3. Set up the Environment's config

As mentioned the Toolkit provides several [Terraform Modules](../terraform/modules) that can be used to provision the environment as per the [Reference Architectures](https://docs.gitlab.com/ee/administration/reference_architectures/). While there are several modules provided with the Toolkit most of these are under the hood. For most users only one easy to use `ref_arch` module will need to be configured.

The `ref_arch` modules configure not only the VMs required for the environment but also things such as storage buckets, networking, labels for Ansible to use and more. There's one `ref_arch` module per host provider and for each there are 3 config files to set up:

- `main.tf` - Contains the main Terraform connection settings such as cloud provider or state backend.
- `environment.tf` - `ref_arch` module configuration (machine count or sizes for example).
- `variables.tf` - Variable definitions.

Each of the above files must be set in the same folder for Terraform to merge. Due to relative path requirements in Terraform we recommend you create these in a unique folder for your environment under the provided [`terraform/environments` folder](../terraform/environments), e.g. `terraform/environments/<env_name>`. This documentation will assume this is the case from now on.

In this step there are sections for each supported host provider on how to configure the above files. Follow the section for your selected provider and then move onto the next step.

### Google Cloud Platform (GCP)

The Toolkit's module for seamlessly setting up a full GitLab Reference architecture on GCP is **[`gitlab_ref_arch_gcp`](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/tree/main/terraform/modules/gitlab_ref_arch_gcp)**.

In this section we detail all that's needed to configure it.

#### Configure Variables (`variables.tf`)

First we configure the variables needed in the `variables.tf` file as these are used in the other files.

Here's an example of the file with all config and descriptions below. Items in `<>` brackets need to be replaced with your config:

```tf
variable "prefix" {
  default = "<environment_prefix>"
}

variable "project" {
  default = "<project_id>"
}

variable "region" {
  default = "<project_region>"
}

variable "zone" {
  default = "<project_zone>"
}

variable "external_ip" {
  default = "<external_ip>"
}
```

- `prefix` - Used to set the names and labels of the VMs consistently. Use a unique name to avoid any clashes. Once set, do not change. An example of what this could be is `gitlab-test`
- `project` - The [ID](https://support.google.com/googleapi/answer/7014113?hl=en) of the GCP project the environment is to be deployed to.
- `region` - The GCP region of the project, e.g. `us-east1`.
- `zone` - The default GCP zone of the project, e.g. `us-east1-c`.
- `external_ip` - The static external IP the environment will be accessible one. Previously created in the [Create Static External IP - GCP](environment_prep.md#6-create-static-external-ip-gcp) step.

#### Configure Terraform settings (`main.tf`)

The next file to configure is the main Terraform settings file - `main.tf`. In this file will be the main connection details for Terraform to connect to GCP as well as where to store its state.

Here's an example of the file with descriptions below. Items in `<>` brackets need to be replaced with your config:

```tf
terraform {
  backend "gcs" {
    bucket  = "<state_gcp_storage_bucket_name>"
    prefix = "<environment_prefix>"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}
```

- `terraform` - The main Terraform config block.
  - `backend "gcs"` - The [`gcs` backend](https://developer.hashicorp.com/terraform/language/backend/gcs) config block.
    - `bucket` - The name of the bucket [previously created](environment_prep.md#5-setup-terraform-state-storage-bucket-gcp-cloud-storage) to store the State.
    - `prefix` - The name of the folder to create in the bucket to store the State.
  - `required_providers` - Config block for the required provider(s) Terraform needs to download and use.
    - `google` - Config block for the GCP provider. Sets where to source the provider and what version to download and use.
- `provider "google"` - Config block for the [Google provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs).
  - `project` - The [ID](https://support.google.com/googleapi/answer/7014113?hl=en) of the GCP project to connect to. Set in `variables.tf`.
  - `region` - The GCP region of the project. Set in `variables.tf`.
  - `zone` - The default GCP zone of the project. Set in `variables.tf`.

#### Configure Module settings (`environment.tf`)

Next to configure is `environment.tf`. This file contains all the config for the `gitlab_ref_arch_gcp` module such as machine counts, machine sizes or external IP.

Configure this file depending on the size of [Reference Architecture](https://docs.gitlab.com/ee/administration/reference_architectures/) you want to deploy. Below is an example of how a [10k](https://docs.gitlab.com/ee/administration/reference_architectures/10k_users.html) `environment.tf` file is set. If a different size is desired, change the machine counts and sizes to match the desired Reference Architecture as shown in the [docs](https://docs.gitlab.com/ee/administration/reference_architectures/).

Here's an example of the file with all config for a [10k Reference Architecture](https://docs.gitlab.com/ee/administration/reference_architectures/10k_users.html) and descriptions below:

```tf
module "gitlab_ref_arch_gcp" {
  source = "../../modules/gitlab_ref_arch_gcp"

  prefix = var.prefix
  project = var.project

  # 10k
  consul_node_count = 3
  consul_machine_type = "n1-highcpu-2"

  opensearch_vm_node_count = 3
  opensearch_vm_machine_type = "n1-highcpu-16"

  gitaly_node_count = 3
  gitaly_machine_type = "n1-standard-16"

  praefect_node_count = 3
  praefect_machine_type = "n1-highcpu-2"

  praefect_postgres_node_count = 1
  praefect_postgres_machine_type = "n1-highcpu-2"

  gitlab_rails_node_count = 3
  gitlab_rails_machine_type = "n1-highcpu-32"

  haproxy_external_node_count = 1
  haproxy_external_machine_type = "n1-highcpu-2"
  haproxy_external_external_ips = [var.external_ip]
  haproxy_internal_node_count = 1
  haproxy_internal_machine_type = "n1-highcpu-2"

  monitor_node_count = 1
  monitor_machine_type = "n1-highcpu-4"

  pgbouncer_node_count = 3
  pgbouncer_machine_type = "n1-highcpu-2"

  postgres_node_count = 3
  postgres_machine_type = "n1-standard-4"

  redis_cache_node_count = 3
  redis_cache_machine_type = "n1-standard-4"
  redis_persistent_node_count = 3
  redis_persistent_machine_type = "n1-standard-4"

  sidekiq_node_count = 4
  sidekiq_machine_type = "n1-standard-4"
}

output "gitlab_ref_arch_gcp" {
  value = module.gitlab_ref_arch_gcp
}
```

- `module "gitlab_ref_arch_gcp"` - Module config block with name.
  - `source` - The relative path to the `gitlab_ref_arch_gcp` module. We assume you're creating config in the `terraform/environments/` folder here but if you're in a different location this setting must be updated to the correct path.
  - `prefix` - The name prefix of the project. Set in `variables.tf`.
  - `project` - The [ID](https://support.google.com/googleapi/answer/7014113?hl=en) of the GCP project to connect to. Set in `variables.tf`.

Next in the file are the various machine settings, separated the same as the Reference Architectures. To avoid repetition we'll describe each setting once:

- `*_node_count` - The number of machines to set up for that component
- `*_machine_type` - The [GCP Machine Type](https://cloud.google.com/compute/docs/machine-types) (size) for that component.
- `*_disk_size` - The size of root disk to assign to the machine. For Gitaly and OpenSearch machines this defaults to `500` (GB). For all other machines they fall back to `default_disk_size`, which defaults to `100` (GB).
- `*_disk_type` - The [GCP disk type](https://cloud.google.com/compute/docs/disks/performance#type_comparison) that should be used for the root disk. For Gitaly and OpenSearch machines this defaults to `pd-ssd`. If not set, this defaults to `default_disk_type`, which is set to `pd-standard`.
  > [!note]
  > Disk IOPS performance in GCP is determined not only by the disk type but also several other factors such as CPU and storage size. [Refer to the GCP documentation for more information](https://cloud.google.com/compute/docs/disks/performance).
- `haproxy_external_external_ips` - Set the external HAProxy load balancer to assume the external IP set in `variables.tf`. Note that this is an array setting as the advanced underlying functionality needs to account for the specific setting of IPs for potentially multiple machines. In this case though it should always only be one IP.
- `gitlab_rails_external_ips` - Only for Single Node environments without a load balancer - Set the GitLab Rails node to assume the external IP set in `variables.tf`. Note that this is an array setting as the advanced underlying functionality needs to account for the specific setting of IPs for potentially multiple machines. In this case though it should always only be one IP. This setting should be used when deploying single Rails node without external load balancer.

> [!note]
> Redis prefixes depend on the target Reference Architecture - set `redis_*` for combined Redis, `redis_cache_*` and `redis_persistent_*` for separated Redis setup.

The following optional settings are available for configuring node and disk setup:

- `machine_image` - The [GCP machine image name](https://cloud.google.com/compute/docs/images/os-details) to use for the VMs. Supported OS versions are listed [in the README](../README.md#requirements). Defaults to `ubuntu-2404-lts-amd64`.
- `machine_secure_boot` - Controls whether [Secure Boot](https://cloud.google.com/security/shielded-cloud/shielded-vm#secure-boot) is enabled on the VMs. Can only be enabled for OS Images that support the `Shielded VM` feature. Defaults to `false`.
- `default_disk_size` - The default root disk size to use for machines where a specific default has not been set. Defaults to `100` (GB).
- `default_disk_type` - The default root disk type to use for machines where a specific default has not been set. Defaults to `pd-standard`.
- `allow_stopping_for_update` - Controls whether Terraform can restart VMs when making changes if required. Should only be disabled for additional resilience. Defaults to `true`.

The following optional settings are available for configuring Object Storage setup:

> [!warning]
> Changing the `object_storage_buckets`, `object_storage_prefix` or `object_storage_location` settings on an existing environment can lead to buckets getting removed and data loss.

- `object_storage_buckets` - The list of buckets Terraform should create. By default, this will create every type of bucket GitLab uses. This list can be adjusted for advanced scenarios where only select buckets are wanted. 
- `object_storage_prefix` - An optional prefix to use for the bucket names instead of `prefix`. Can be used to ensure unique names for buckets. 
- `object_storage_location` - The [GCS Location](https://cloud.google.com/storage/docs/locations) buckets are created in. Refer to the [Object Storage Location (GCP)](#object-storage-location-gcp) below for more info.
- `object_storage_force_destroy` - Controls whether Terraform can delete all objects (including any locked objects) from the bucket so that the bucket can be destroyed without error. Consider setting this value to `false` for production systems. Defaults to `true`.
- `object_storage_versioning` - Controls whether Terraform will enable [versioning in GCS buckets](https://cloud.google.com/storage/docs/object-versioning). Defaults to `false`.

> [!tip]
> To add custom labels to the different resources created by Terraform you can follow the steps in the [Custom Tags/Labels](environment_advanced.md#custom-tagslabels) documentation.

##### Configure Machine OS Image (GCP)

By default, the Toolkit will configure machines using Ubuntu 24.04.

However, this can be changed via the `machine_image` in the [module's environment config file](#configure-module-settings-environmenttf) to the [machine image name as given by GCP](https://cloud.google.com/compute/docs/images/os-details), e.g. `ubuntu-2204-lts` or `rhel-8`.

> [!note]
> See [Target Node Operating System Support](environment_configure.md#target-node-operating-system-support) for details on supported Operating System targets with Ansible.

> [!note]
> Changing the `machine_image` setting after deployment typically would trigger every node to be rebuilt. For this reason, the Terraform modules in the Toolkit have been explicitly configured to ignore any changes once deployed. It's recommended to upgrade the OS via it's standard process, for more information refer to [this section](environment_upgrades.md#avoid-changing-machine-os-image).

##### Object Storage options (GCP)

This section gives more detail on the available options for configuring GCP Object Storage buckets for GitLab.

###### Object Storage location (GCP)

GCP Buckets are created in the `US` multi-region by default [in the Terraform GCP provider](https://registry.terraform.io/providers/wiardvanrij/ipv4google/latest/docs/resources/storage_bucket#location-1).

For optimal performance, you should configure the location to a [region](https://cloud.google.com/storage/docs/locations#location-r) or [multi-region](https://cloud.google.com/storage/docs/locations#location-mr) close to your environment as desired via the `object_storage_location` setting.

> [!warning]
> Changing bucket location on existing environments destroys all buckets and their data.

###### Object Storage versioning (GCP)

The Toolkit can enable [versioning in Google Cloud Storage buckets](https://cloud.google.com/storage/docs/object-versioning) within GCP by setting the `object_storage_versioning` flag to `true`. This will enable the storing of multiple variants of an object in the same bucket.

As this can lead to increased storage costs it is recommended to set up an [Object Lifecycle Management](https://cloud.google.com/storage/docs/lifecycle) separately to remove older versions of stored objects.

##### Storage Encryption (GCP)

[GCP by default encrypts storage with service provided encryption keys](https://cloud.google.com/docs/security/encryption/default-encryption#googles_default_encryption) across all services.

However, it's also possible to encrypt with custom keys, known as Customer managed encryption keys (CMEK). Refer to the below section for more information.

###### Customer managed encryption keys (CMEK) (GCP)

The Toolkit allows for you to configure encrypting storage with [Customer-managed encryption keys (CMEK)](https://cloud.google.com/kms/docs/cmek) on GCP.

>>> [!important]
Enabling CMEK is irreversible and key mismanagement can cause data loss. Refer to the [Cloud Provider's documentation](https://cloud.google.com/kms/docs/cmek) for more information.

Ongoing management of keys such as rotations are not within the scope of this documentation. Refer to the [GCP service's respective documentation](https://cloud.google.com/kms/docs/compatible-services#cmek_integrations) for further guidance.
>>>

- Keys must be available in Cloud KMS and in the same location as the intended environment and services.
- The [Cloud KMS CryptoKey Encrypter/Decrypter](https://cloud.google.com/iam/docs/understanding-roles#cloudkms.cryptoKeyEncrypterDecrypter) role must be granted on the key(s) for the associated Service Agent or Service Account depending on the service:
  - Compute Engine / Kubernetes Engine - [Compute Service Agent](https://cloud.google.com/compute/docs/disks/customer-managed-encryption#required-roles).
  - Cloud Storage - [Cloud Storage Service Agent](https://cloud.google.com/storage/docs/encryption/using-customer-managed-keys).
  - Cloud SQL - [System Service Account](https://cloud.google.com/sql/docs/postgres/configure-cmek#service-account).
  - Memorystore - [System Service Account](https://cloud.google.com/memorystore/docs/redis/use-cmek#granting_the_service_account_access_to_the_key).
- Using CMEK with Google Cloud Object Storage is supported for [GitLab versions `16.11` and higher](https://docs.gitlab.com/ee/administration/object_storage.html#google-cloud-storage-gcs).
- CMEK can only be configured for new environments builds on all applicable services except Object Storage, which can be changed, but [additional manual actions will be required](https://cloud.google.com/storage/docs/encryption/customer-managed-keys#key-replacement).

Once the Key(s) are created they can be configured in Terraform via the [module's environment config file](#configure-module-settings-environmenttf) with the following variables:

> [!tip]
> GCP Key resource names will be in the format `projects/<project-id>/locations/<location>/keyRings/<keyring-name>/cryptoKeys/<key-name>`

- `default_disk_kms_key` - The GCP Key resource name to use for all disk storages across GCE Component VMs. Defaults to `null`.
  - `*_disk_kms_key` - The GCP Key resource name to use for specific component VM disks. Will override `default_disk_kms_key` if specified. Default is `null`.
    - Available component options: `consul`, `postgres`, `pgbouncer`, `redis`, `redis_cache`, `redis_persistent`, `praefect_postgres`, `praefect`, `gitaly`, `gitlab_rails`, `sidekiq`, `monitor`, `opensearch_vm`, `gitlab_nfs`, `haproxy_external` and `haproxy_internal`.
- `object_storage_kms_key` - The GCP Key resource name to use for all Object Storage buckets. Defaults to `null`.
- `gke_default_disk_kms_key` - The GCP Key resource name to use for all disk storages across GKE Node Pools. Defaults to `null`.
  - `*_node_pool_disk_kms_key` - The GCP Key resource name to use for specific GKE Node Pools. Will override `gke_default_disk_kms_key` if specified. Default is `null`.
    - Available component options: `webservice`, `sidekiq`, `supporting`.
- `cloud_sql_postgres_encryption_key_name` - The GCP Key resource name to be used for storage encryption of a [Google Cloud SQL](environment_advanced_services.md#gcp-cloud-sql) instance created by the Toolkit.
  - Optionally `cloud_sql_praefect_postgres_encryption_key_name` or `cloud_sql_geo_tracking_postgres_encryption_key_name` can be used to configure for separate services.
- `memorystore_redis_customer_managed_key` - The GCP Key resource name to be used for storage encryption of a [GCP Memorystore](environment_advanced_services.md#gcp-memorystore) instance created by the Toolkit.
  - Optionally `memorystore_redis_cache_customer_managed_key` or `memorystore_redis_persistent_customer_managed_key` can be used to configure for separate services.

##### Network options (GCP)

This section gives more detail on the available options for configuring GCP networking for GitLab.

###### Configure Network Setup (GCP)

By default, the Toolkit sets up the infrastructure on the default network stack as provided by GCP. However, it can also support other advanced setups such as creating a new network or using an existing one. To learn more refer to [Configure network setup (GCP)](environment_advanced_network.md#configure-network-setup-gcp).

###### Configure Network Zones (GCP)

With GCP you can spread optionally spread resources across multiple [Availability Zones](https://cloud.google.com/compute/docs/regions-zones) in the selected region, overriding the default Zone configured in `variables.tf`. By doing this it adds additional resilience for the environment in the case a Zone ever went down.

> [!note]
> Cross Zone networking has additional costs. Refer to the [GCP pricing page](https://cloud.google.com/vpc/network-pricing) for more info.

No matter what Network design above you have selected, spreading resources across Zones can also be applied in the [module's environment config file](#configure-module-settings-environmenttf) with the following variables:

- `zones` - A list of Zone names that resources should be spread across. Default is `null`. Optional.

An example of your environment config file then would look like when using the Default network in the `us-east1` region:

```tf
module "gitlab_ref_arch_gcp" {
  source = "../../modules/gitlab_ref_arch_gcp"

  prefix = var.prefix
  project = var.project

  zones = ["us-east1-b", "us-east1-c", "us-east1-d"]

  [...]
}
```

Note that the default zone configured in `variables.tf` is still required in this setup as a backup for other resources.

##### Service Account options (GCP)

As per recommended [best practices](https://cloud.google.com/compute/docs/access/create-enable-service-accounts-for-instances#best_practices), the Toolkit will provision and configure the least privileged Service Accounts for GCP resources as required. These accounts are created by whatever account Terraform is running with, which can itself also be a Service Account.

While this is designed to be seemless there are several options available to adjust how Terraform will create or set up these accounts. These are detailed in this section.

###### Service Account User members (GCP)

GCP requires the [`Service Account User` role](https://cloud.google.com/iam/docs/understanding-roles#iam.serviceAccountUser) for members to in turn use Service Accounts, such as for attachment to nodes and [SSH OS login](https://cloud.google.com/compute/docs/oslogin/set-up-oslogin#configure_users). Following [GCP best practices](https://cloud.google.com/iam/docs/best-practices-service-accounts#project-folder-grants) the role is not recommended to be assigned as the project level. As such, the Toolkit attaches this role per Service Account to the member running Terraform by default.

To prevent provisioning and SSH login errors when multiple members need to run Terraform, you may need to configure a static list of all expected members in the [module's environment config file](#configure-module-settings-environmenttf) via the following variable:

> [!caution]
> Members configured via this list will be able to impersonate the Service Accounts created by the toolkit. Caution should be exercised to only add members to this list that are required.

- `service_account_user_members` - List of GCP IAM identities that will be granted the `Service Account User` role on each created Service Account. This should include the member accounts being used by Terraform and Ansible (for SSH OS Login). Each entrant on the list must follow the [GCP format](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account_iam#member/members). If not set the role will be set to the account running Terraform. Optional, default is `[]`.

###### Service Account Prefix (GCP)

Due to length limits on Service Account IDs (30 characters or fewer), the Toolkit aims to ensure a consistent naming scheme by using the set prefix `gl` by default.

For most use cases this will work without any intervention. However, if you intend to deploy more than one environment in the same GCP project you will see this cause a clash accordingly. To help with this scenario the prefix can be configured in the [module's environment config file](#configure-module-settings-environmenttf) via the following variable:

- `service_account_prefix` - Sets the prefix the Toolkit will use when generating Service Accounts. To comply with GCP limits the prefix must be 10 characters or fewer and only contain alphanumeric and dash (`-`) characters. This should only be changed if the IDs are expected to clash in your GCP project. Optional, default is `gl`.

An example of setting this in your environment config file would be as follows:

```tf
module "gitlab_ref_arch_gcp" {
  source = "../../modules/gitlab_ref_arch_gcp"

  prefix = var.prefix
  project = var.project

  service_account_prefix = "gl2k"

  [...]
}
```

#### Configure Authentication (GCP)

Finally, the last thing to configure is authentication. This is required to allow Terraform to access GCP (provider) as well as its State Storage Bucket (backend).

Terraform provides multiple ways to authenticate with the [provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#authentication) and [backend](https://developer.hashicorp.com/terraform/language/backend/gcs#configuration-variables), you can select any method that is desired.

All the methods given involve the Service Account file you generated previously. We've found the authentication methods that work best with the Toolkit in terms of ease of use are as follows:

- `GOOGLE_CREDENTIALS` environment variable - This environment variable is picked up by both the provider and backend, meaning it only needs to be set once. It's particularly useful with CI pipelines. The variable should be set to the path of the Service Account key file.
- `gcloud` login - Authentication can also occur automatically through the [`gcloud`](https://cloud.google.com/sdk/gcloud/reference/auth/application-default) command line tool. To log in with the Service Account you created earlier the [`activate-service-account`](https://cloud.google.com/sdk/gcloud/reference/auth/activate-service-account) command is available.

### Amazon Web Services (AWS)

The Toolkit's module for seamlessly setting up a full GitLab Reference architecture on AWS is **[`gitlab_ref_arch_aws`](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/tree/main/terraform/modules/gitlab_ref_arch_aws)**.

In this section we detail all that's needed to configure it.

#### Configure Variables (`variables.tf`)

First we configure the variables needed in the `variables.tf` file as these are used in the other files.

Here's an example of the file with all config and descriptions below. Items in `<>` brackets need to be replaced with your config:

```tf
variable "prefix" {
  default = "<environment_prefix>"
}

variable "region" {
  default = "<region>"
}

variable "ssh_public_key_file" {
  default = "<ssh_public_key_file>"
}

variable "external_ip_allocation" {
  default = "<external_ip_allocation>"
}
```

- `prefix` - Used to set the names and labels of the VMs consistently. Use a unique name to avoid any clashes. Once set, do not change. An example of what this could be is `gitlab-test`
- `region` - The AWS region of the project.
- `ssh_public_key_file` - Path to the public SSH key file. Previously created in the [Setup SSH Authentication - AWS](environment_prep.md#2-setup-ssh-authentication-aws) step. Not required if another connection method is being used.
- `external_ip_allocation` - The Allocation ID for the static external IP the environment will be accessible on. Previously created in the [Create Static External IP - AWS Elastic IP Allocation](environment_prep.md#4-create-static-external-ip-aws-elastic-ip-allocation) step.

> [!tip]
> Choose a unique prefix that doesn't conflict with other environments in your AWS account. Some AWS resources require unique names globally all accounts.

#### Configure Terraform settings (`main.tf`)

The next file to configure is the main Terraform settings file - `main.tf`. In this file will be the main connection details for Terraform to connect to AWS as well as where to store its state.

Here's an example of the file with descriptions below. Items in `<>` brackets need to be replaced with your config:

```tf
terraform {
  backend "s3" {
    bucket = "<state_aws_storage_bucket_name>"
    key    = "<state_file_path_and_name>"
    region = "<state_aws_storage_bucket_region>"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}
```

- `terraform` - The main Terraform config block.
  - `backend "s3"` - The [`s3` backend](https://developer.hashicorp.com/terraform/language/backend/s3) config block.
    - `bucket` - The name of the bucket [previously created](environment_prep.md#3-setup-terraform-state-storage-aws-s3) to store the State.
    - `key` - The file path and name to store the state in (example: `path/to/my/key`- [must not start with '/'](https://github.com/hashicorp/terraform/blob/main/internal/backend/remote-state/s3/backend.go#L30-L41)).
    - `region` - The AWS region of the bucket.
  - `required_providers` - Config block for the required provider(s) Terraform needs to download and use.
    - `aws` - Config block for the AWS provider. Sets where to source the provider and what version to download and use.
- `provider "aws"` - Config block for the [AWS provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs).
  - `region` - The AWS region of the project. Set in `variables.tf`.

#### Configure Module settings (`environment.tf`)

Next to configure is `environment.tf`. This file contains all the config for the `gitlab_ref_arch_aws` module such as instance counts, instance sizes or external IP.

How you configure this file depends on the size of [Reference Architectures](https://docs.gitlab.com/ee/administration/reference_architectures/) you want to deploy. Below we show how a [10k](https://docs.gitlab.com/ee/administration/reference_architectures/10k_users.html) `environment.tf` would be set. If a different size is required all that's required is to tweak the machine counts and sizes to match the desired Reference Architecture as shown in the [docs](https://docs.gitlab.com/ee/administration/reference_architectures/).

Here's an example of the file with all config for a [10k Reference Architecture](https://docs.gitlab.com/ee/administration/reference_architectures/10k_users.html) and descriptions below:

```tf
module "gitlab_ref_arch_aws" {
  source = "../../modules/gitlab_ref_arch_aws"

  prefix = var.prefix
  ssh_public_key = file(var.ssh_public_key_file)

  # 10k
  consul_node_count = 3
  consul_instance_type = "c5.large"

  opensearch_vm_node_count = 3
  opensearch_vm_instance_type = "c5.4xlarge"

  gitaly_node_count = 3
  gitaly_instance_type = "m5.4xlarge"

  praefect_node_count = 3
  praefect_instance_type = "c5.large"

  praefect_postgres_node_count = 1
  praefect_postgres_instance_type = "c5.large"

  gitlab_rails_node_count = 3
  gitlab_rails_instance_type = "c5.9xlarge"

  haproxy_external_node_count = 1
  haproxy_external_instance_type = "c5.large"
  haproxy_external_elastic_ip_allocation_ids = [var.external_ip_allocation]
  haproxy_internal_node_count = 1
  haproxy_internal_instance_type = "c5.large"

  monitor_node_count = 1
  monitor_instance_type = "c5.xlarge"

  pgbouncer_node_count = 3
  pgbouncer_instance_type = "c5.large"

  postgres_node_count = 3
  postgres_instance_type = "m5.2xlarge"

  redis_cache_node_count = 3
  redis_cache_instance_type = "m5.xlarge"
  redis_persistent_node_count = 3
  redis_persistent_instance_type = "m5.xlarge"

  sidekiq_node_count = 4
  sidekiq_instance_type = "m5.xlarge"
}

output "gitlab_ref_arch_aws" {
  value = module.gitlab_ref_arch_aws
}
```

- `module "gitlab_ref_arch_aws"` - Module config block with name.
  - `source` - The relative path to the `gitlab_ref_arch_aws` module. We assume you're creating config in the `terraform/environments/` folder here but if you're in a different location this setting must be updated to the correct path.
  - `prefix` - The name prefix of the project. Set in `variables.tf`.
  - SSH key configuration - There are 3 options for SSH configuration settings; provide the public key, provide a key pair name, or set neither variable to forgo the use of ssh connection method.
    - `ssh_public_key` - The SSH key value, typically read from an SSH key file set as `ssh_public_key_file` in `variables.tf`. Not required if another connection method is being used.
    - `ssh_key_name` - The name of a Key Pair that is already available in your AWS Account and Region. You will need access the associated private key to leverage this variable.

Next in the file are the various machine settings, separated the same as the Reference Architectures. To avoid repetition we'll describe each setting once:

- `*_node_count` - The number of machines to set up for that component
- `*_instance_type` - The [AWS Instance Type Machine Type](https://aws.amazon.com/ec2/instance-types/) (size) for that component
- `*_disk_size` - The size of root disk to assign to the machine. For Gitaly and OpenSearch machines this defaults to `500` (GB). For all other machines they fall back to `default_disk_size`, which defaults to `100` (GB).
- `*_disk_type` - The [AWS disk type](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-volume-types.html) or root disks. HDD types (`st1` / `sc1`) are not supported for root disks. If not set, this defaults to `default_disk_type` of `gp3`.
  > [!note]
  > The default [`gp3` General Purpose SSD type](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/general-purpose.html#gp3-ebs-volume-type) provides 3000 baseline IOPS. Additional IOPS can be configured for select components as follows:
  - `gitaly_disk_iops` - The amount of total IOPS to provision for the Gitaly node root disks. Defaults to `8000`.
- `*_disk_delete_on_termination` - (Optional) Whether the root volume should be destroyed on instance termination. Defaults to `true`.
- `haproxy_external_elastic_ip_allocation_ids` - Set the external HAProxy load balancer to assume the external IP allocation ID set in `variables.tf`. Note that this is an array setting as the advanced underlying functionality needs to account for the specific setting of IPs for potentially multiple machines. In this case though it should always only be one IP allocation ID.
- `gitlab_rails_elastic_ip_allocation_ids` - Only for Single Node environments without a load balancer - Set the GitLab Rails node to assume the external IP allocation ID set in `variables.tf`. Note that this is an array setting as the advanced underlying functionality needs to account for the specific setting of IPs for potentially multiple machines. In this case though it should always only be one IP allocation ID. This setting should be used when deploying single Rails node without external load balancer.

> [!note]
> Redis prefixes depend on the target Reference Architecture - set `redis_*` for combined Redis, `redis_cache_*` and `redis_persistent_*` for separated Redis setup.

The following optional settings are available for configure disk setup:

- `default_disk_size` - The default root disk size to use for machines where a specific default has not been set. Defaults to `100` (GB).
- `default_disk_type` - The default root disk type to use for machines where a specific default has not been set. Defaults to `gp3`.
- `*_user_data_base64` - Custom [EC2 user data](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html) to pass to the machine. Default is `null`.

The following optional settings are available for configuring Object Storage setup:

> [!warning]
> Changing the `object_storage_buckets` or `object_storage_prefix` settings on an existing environment can lead to buckets getting removed and data loss.

- `object_storage_buckets` - The list of buckets Terraform should create. By default, this will create every type of bucket GitLab uses. This list can be adjusted for advanced scenarios where only select buckets are wanted.
- `object_storage_prefix` - An optional prefix to use for the bucket names instead of `prefix`. Can be used to ensure unique names for buckets.
- `object_storage_force_destroy` - Controls whether Terraform can delete all objects (including any locked objects) from the bucket so that the bucket can be destroyed without error. Consider setting this value to `false` for production systems. Defaults to `true`.
- `object_storage_versioning_status` - [S3 bucket versioning status](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning#versioning_configuration). Valid values are `"Enabled"` (stores multiple object variants), `"Suspended"` (suspend versioning but keep existing versions for cost optimization), or `Disabled` (no versioning configuration). If not set no configuration is passed and the default on AWS's side of `Disabled` is used. Defaults to `null`.
- `object_storage_block_public_access` - Controls whether [public access](https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-control-block-public-access.html) is blocked for object storage. Should only be changed when public access to objects is required, for example [Proxy Download](https://docs.gitlab.com/ee/administration/object_storage.html#proxy-download). Optional, default is `true`.

> [!tip]
> To add custom labels to the different resources created by Terraform you can follow the steps in the [Custom Tags/Labels](environment_advanced.md#custom-tagslabels) documentation.

##### Configure Machine OS Image (AWS)

By default, the Toolkit will configure machines using the latest Ubuntu 24.04 AMI.

However, this can be changed via the `ami_id` setting in the [module's environment config file](#configure-module-settings-environmenttf). [Refer to the AWS docs on how to find the specific AMI ID you require](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/finding-an-ami.html).

> [!note]
> See [Target Node Operating System Support](environment_configure.md#target-node-operating-system-support) for details on supported Operating System targets with Ansible.

> [!note]
> Changing the `ami_id` setting after deployment typically would trigger every node to be rebuilt. For this reason, the Terraform modules in the Toolkit have been explicitly configured to ignore any changes once deployed. It's recommended to upgrade the OS via it's standard process, for more information refer to [this section](environment_upgrades.md#avoid-changing-machine-os-image).

##### Object Storage versioning (AWS)

The Toolkit can enable [versioning in S3 buckets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning#versioning_configuration) within AWS by configuring the `object_storage_versioning_status` setting to `"Enabled"`. This will enable the storing of multiple variants of an object in the same bucket.

As this can lead to increased storage costs it is recommended to set up a [storage lifecycle configuration](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html) separately to remove older versions of stored objects.

##### Configure network setup (AWS)

By default, the toolkit sets up the infrastructure on the default network stack as provided by AWS. However, it can also support other advanced setups such as creating a new network or using an existing one. To learn more refer to [Configure network setup (AWS)](environment_advanced_network.md#configure-network-setup-aws).

##### Storage Encryption (AWS)

The Toolkit encrypts all storage by default using:

1. [AWS managed KMS keys](https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#kms_keys) where available
1. Customer managed encryption keys (CMEK) - can be configured globally or per service/storage

The Toolkit applies these in order of precedence of customer managed encryption keys then AWS managed/created keys.

Encryption configuration options are detailed below in this section.

> [!warning]
> Changing encryption settings on existing environments can destroy and recreate storage resources, causing data loss.

###### Default Encryption

Encryption is enabled by default for all storages and services using either AWS managed keys.

For S3 Object Storage, which has various options, the selected default encryption type is [`SSE-KMS`](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingKMSEncryption.html) with [S3 Bucket Keys](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucket-key.html) enabled.

###### Customer managed encryption keys (CMEK) (AWS)

The Toolkit allows for you to configure encrypting storage with [Customer-managed encryption keys (CMEK)](https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#customer-cmk) on AWS instead of service provided keys.

>>> [!important]
Enabling CMEK is irreversible and key mismanagement can cause data loss. Refer to the [Cloud Provider's documentation](https://docs.aws.amazon.com/kms/latest/developerguide/overview.html) for more information.

Ongoing management of keys such as rotations are not within the scope of this documentation. Refer to the AWS service's respective documentation for further guidance.
>>>

Creating and managing the key(s) should be done before running the Toolkit and have the following requirements:

- Keys must be available in AWS KMS and in the same location as the intended environment and services.
- Keys must be configured with the correct policies for the following services as required:
  - [EKS Node Group Disks](https://docs.aws.amazon.com/autoscaling/ec2/userguide/key-policy-requirements-EBS-encryption.html) - Policy required on Key to allow the `AWSServiceRoleForAutoScaling` service-linked role access.
- CMEK can only be configured for new environments builds on all applicable services except [S3 Object Storage](https://docs.aws.amazon.com/AmazonS3/latest/userguide/specifying-kms-encryption.html) and [OpenSearch service](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/encryption-at-rest.html), which can be changed, but additional manual actions will be required for existing data.

Once the Key(s) are created they can be configured in Terraform via the [module's environment config file](#configure-module-settings-environmenttf) with the following variables:

- `default_disk_kms_key_arn` - The AWS KMS key ARN to be used for a specific component VM disks. Default is `null`.
  - Available component options: `consul`, `postgres`, `pgbouncer`, `redis`, `redis_cache`, `redis_persistent`, `praefect_postgres`, `praefect`, `gitaly`, `gitlab_rails`, `sidekiq`, `monitor`, `opensearch_vm`, `gitlab_nfs`, `haproxy_external` and `haproxy_internal`.
- `object_storage_kms_key_arn` - The AWS KMS key ARN to be used for a S3 Object Storage buckets. Default is `null`.
- `eks_default_disk_kms_key_arn` - The AWS KMS key ARN to be used for EKS Node Group VM disks. Default is `null`.
  - `*_node_pool_disk_kms_key_arn` - The AWS KMS key ARN to be used for specific EKS Node Group VM disks. Will override `eks_default_disk_kms_key_arn` if specified. Default is `null`.
    - Available component options: `webservice`, `sidekiq`, `supporting`.
- `rds_postgres_kms_key_arn` - The AWS KMS key ARN to be used to encrypt the database instance on first creation. Optional, default is `null`.
  - `rds_praefect_postgres_kms_key_arn` or `rds_geo_tracking_postgres_kms_key_arn` when setting up separate databases.
- `elasticache_redis_kms_key_arn` - The AWS KMS key ARN to be used to encrypt the Redis instance on first creation. Optional, default is `null`.
  - `elasticache_redis_cache_kms_key_arn` or `elasticache_redis_persistent_kms_key_arn` when setting up separate services.
- `opensearch_service_kms_key_arn` - The AWS KMS key ARN to be used to encrypt the OpenSearch domain. Optional, default is `null`.

#### Configure Authentication (AWS)

Finally, the last thing to configure is authentication. This is required to allow Terraform to access AWS (provider) as well as its State Storage Bucket (backend).

Terraform provides multiple ways to authenticate with the [provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication) and [backend](https://developer.hashicorp.com/terraform/language/backend/s3#configuration), you can select any method that is desired.

All the methods given involve the AWS Access Key you generated previously. We've found that the easiest and secure way to do this is with the official [environment variables](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#environment-variables):

- `AWS_ACCESS_KEY_ID` - Set to the AWS Access Key.
- `AWS_SECRET_ACCESS_KEY` - Set to the AWS Secret Key.

Once the two variables are either set locally or in your CI pipeline Terraform will be able to fully authenticate for both the provider and backend.

### Azure

The Toolkit's module for seamlessly setting up a full GitLab Reference architecture on Azure is **[`gitlab_ref_arch_azure`](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/tree/main/terraform/modules/gitlab_ref_arch_azure)**.

In this section we detail all that's needed to configure it.

#### Configure Variables (`variables.tf`)

First we configure the variables needed in the `variables.tf` file as these are used in the other files.

Here's an example of the file with all config and descriptions below. Items in `<>` brackets need to be replaced with your config:

```tf
variable "prefix" {
  default = "<environment_prefix>"
}

variable "resource_group_name" {
  default = "<resource_group_name>"
}

variable "location" {
  default = "<location>"
}

variable "vm_admin_username" {
  default = "<vm_admin_username>"
}

variable "ssh_public_key_file_path" {
  default = "<ssh_public_key_file_path>"
}

variable "storage_account_name" {
  default = "<storage_account_name>"
}

variable "external_ip_name" {
  default = "<external_ip_name>"
}

```

- `prefix` - Used to set the names and labels of the VMs consistently. Use a unique name to avoid any clashes. Once set, do not change. An example of what this could be is `gitlab-test`
- `resource_group_name` - The name of the resource group previously created in the [Create Azure Resource Group](environment_prep.md#1-create-azure-resource-group) step.
- `location` - The Azure location of the resource group.
- `vm_admin_username` - The username of the local administrator that will be used for the virtual machines. Previously created in the [Setup SSH Authentication - Azure](environment_prep.md#3-setup-ssh-authentication-azure) step.
- `ssh_public_key_file_path` - Path to the public SSH key file. Previously created in the [Setup SSH Authentication - Azure](environment_prep.md#3-setup-ssh-authentication-azure) step.
- `storage_account_name` - The name of the storage account previously created in the [Setup Terraform State Storage - Azure Blob Storage](environment_prep.md#4-setup-terraform-state-storage-azure-blob-storage) step.
- `external_ip_name` - The name of the static external IP the environment will be accessible one. Previously created in the [Create Static External IP - Azure](environment_prep.md#5-create-static-external-ip-azure) step.

#### Configure Terraform settings (`main.tf`)

The next file to configure is the main Terraform settings file - `main.tf`. In this file will be the main connection details for Terraform to connect to AWS as well as where to store its state.

Here's an example of the file with descriptions below. Items in `<>` brackets need to be replaced with your config:

```tf
terraform {
  backend "azurerm" {
    resource_group_name  = "<resource_group_name>"
    storage_account_name = "<storage_account_name>"
    container_name       = "<state_azure_storage_container_name>"
    key                  = "<state_file_path_and_name>"
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  subscription_id = "<azure_subscription_id>"
  features {}
}
```

- `terraform` - The main Terraform config block.
  - `backend "azurerm"` - The [`azurerm` backend](https://developer.hashicorp.com/terraform/language/backend/azurerm) config block.
    - `resource_group_name` - The name of the resource group previously created in the [Create Azure Resource Group](environment_prep.md#1-create-azure-resource-group) step.
    - `storage_account_name` - The name of the storage account previously created in the [Setup Terraform State Storage - Azure Blob Storage](environment_prep.md#4-setup-terraform-state-storage-azure-blob-storage) step.
    - `container_name` - The name of the container [previously created](environment_prep.md#4-setup-terraform-state-storage-azure-blob-storage) to store the State.
    - `key` - The name of the Blob(file) used to store Terraform's State file inside the Storage Container.
  - `required_providers` - Config block for the required provider(s) Terraform needs to download and use.
    - `azurerm` - Config block for the Azure provider. Sets where to source the provider and what version to download and use.
- `provider "azurerm"` - Config block for the [Azure provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs).
  - `subscription_id` - Azure Subscription ID to be used by Terraform.
  - `features` - Used to [customize the behaviour](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#features) of certain Azure Provider resources.

#### Configure Module settings (`environment.tf`)

Next to configure is `environment.tf`. This file contains all the config for the `gitlab_ref_arch_azure` module such as instance counts, instance sizes or external IP.

How you configure this file depends on the size of [Reference Architectures](https://docs.gitlab.com/ee/administration/reference_architectures/) you want to deploy. Below we show how a [10k](https://docs.gitlab.com/ee/administration/reference_architectures/10k_users.html) `environment.tf` would be set. If a different size is required all that's required is to tweak the machine counts and sizes to match the desired Reference Architecture as shown in the [docs](https://docs.gitlab.com/ee/administration/reference_architectures/).

Here's an example of the file with all config for a [10k Reference Architecture](https://docs.gitlab.com/ee/administration/reference_architectures/10k_users.html) and descriptions below:

```tf
module "gitlab_ref_arch_azure" {
  source = "../../modules/gitlab_ref_arch_azure"

  prefix = var.prefix
  resource_group_name = var.resource_group_name
  location = var.location
  storage_account_name = var.storage_account_name
  vm_admin_username = var.vm_admin_username
  ssh_public_key = file(var.ssh_public_key_file_path)
  external_ip_type = "Standard"

  # 10k
  consul_node_count = 3
  consul_size = "Standard_F2s_v2"

  opensearch_vm_node_count = 3
  opensearch_vm_size = "Standard_F16s_v2"

  gitaly_node_count = 3
  gitaly_size = "Standard_D16s_v3"

  praefect_node_count = 3
  praefect_size = "Standard_F2s_v2"

  praefect_postgres_node_count = 1
  praefect_postgres_size = "Standard_F2s_v2"

  gitlab_rails_node_count = 3
  gitlab_rails_size = "Standard_F32s_v2"

  haproxy_external_node_count = 1
  haproxy_external_size = "Standard_F2s_v2"
  haproxy_external_external_ip_names = [var.external_ip_name]
  haproxy_internal_node_count = 1
  haproxy_internal_size = "Standard_F2s_v2"

  monitor_node_count = 1
  monitor_size = "Standard_F4s_v2"

  pgbouncer_node_count = 3
  pgbouncer_size = "Standard_F2s_v2"

  postgres_node_count = 3
  postgres_size = "Standard_D8s_v3"

  redis_cache_node_count = 3
  redis_cache_size = "Standard_D4s_v3"
  redis_persistent_node_count = 3
  redis_persistent_size = "Standard_D4s_v3"

  sidekiq_node_count = 4
  sidekiq_size = "Standard_D4s_v3"
}

output "gitlab_ref_arch_azure" {
  value = module.gitlab_ref_arch_azure
}
```

- `module "gitlab_ref_arch_azure"` - Module config block with name.
  - `source` - The relative path to the `gitlab_ref_arch_azure` module. We assume you're creating config in the `terraform/environments/` folder here but if you're in a different location this setting must be updated to the correct path.
  - `prefix` - The name prefix of the project. Set in `variables.tf`.
  - `resource_group_name` - The name of the resource group. Set in `variables.tf`.
  - `location` - The location of the resource group. Set in `variables.tf`.
  - `storage_account_name` - The name of the storage account. Set in `variables.tf`.
  - `vm_admin_username` - The username of the administrator for the virtual machines. Set in `variables.tf`.
  - `ssh_public_key` - The SSH key value, typically read from an SSH key file set as `ssh_public_key_file` in `variables.tf`.

Next in the file are the various machine settings, separated the same as the Reference Architectures. To avoid repetition we'll describe each setting once:

- `*_node_count` - The number of machines to set up for that component
- `*_size` - The [Azure Machine Size](https://docs.microsoft.com/en-us/azure/virtual-machines/sizes) for that component.
- `*_disk_size` - The size of root disk to assign to the machine. For Gitaly machines this defaults to `4095` (GB) for IOPS requirements. For all other machines they fall back to `default_disk_size`, which defaults to `100` (GB).
- `*_storage_account_type` - The [Azure disk storage account type](https://learn.microsoft.com/en-us/azure/virtual-machines/disks-types) that should be used for the root disk. For Gitaly machines this defaults to `Premium_LRS` (Premium SSD). If not set, this defaults to `default_disk_type`, which is set to `Standard_LRS` (Standard HDD).
  > [!note]
  > Disk IOPS performance in Azure is determined not only by the disk type but also several other factors such as storage size. [Refer to the Azure documentation for more information](https://learn.microsoft.com/en-us/azure/virtual-machines/disks-types#premium-ssd-size).
- `haproxy_external_external_ip_names` - Set the external HAProxy load balancer to assume the external IP name set in `variables.tf`. Note that this is an array setting as the advanced underlying functionality needs to account for the specific setting of IPs for potentially multiple machines. In this case though it should always only be one IP name.
- `gitlab_rails_external_ip_names` - Only for Single Node environments without a load balancer - Set the GitLab Rails node to assume the external IP name set in `variables.tf`. Note that this is an array setting as the advanced underlying functionality needs to account for the specific setting of IPs for potentially multiple machines. In this case though it should always only be one IP name. This setting should be used when deploying single Rails node without external load balancer.

> [!note]
> Redis prefixes depend on the target Reference Architecture - set `redis_*` for combined Redis, `redis_cache_*` and `redis_persistent_*` for separated Redis setup.

The following optional settings are available for configuring node and disk setup:

- `default_disk_size` - The default root disk size to use for machines where a specific default has not been set. Defaults to `100` (GB).
- `default_disk_type` - The default root disk type to use for machines where a specific default has not been set. Defaults to `Standard_LRS`.
- `external_ip_type` - [The type of Public IP](https://docs.microsoft.com/en-us/azure/virtual-network/ip-services/public-ip-addresses) that will be created for each VM. Can be either `Standard` (recommended) or `Basic`. Default is `Basic` for backwards compatibility.

The following optional settings are available for configuring Object Storage setup:

> [!warning]
> Changing the `object_storage_buckets` or `object_storage_prefix` settings on an existing environment can lead to buckets getting removed and data loss.

- `object_storage_buckets` - The list of buckets Terraform should create. By default, this will create every type of bucket GitLab uses. This list can be adjusted for advanced scenarios where only select buckets are wanted. 
- `object_storage_prefix` - An optional prefix to use for the bucket names instead of `prefix`. Can be used to ensure unique names for buckets.

##### Configure Machine OS Image (Azure)

By default, the Toolkit will configure machines using the latest Ubuntu 24.04 AMI.

However, this can be changed via the `source_image_reference` dictionary setting in the [module's environment config file](#configure-module-settings-environmenttf). [Refer to the Azure docs on how to find the specific source image details you require](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/cli-ps-findimage).

When the image has been selected the setting will need the `publisher`, `offer`, `sku` and `version` fields set. For example:

> [!note]
> See [Target Node Operating System Support](environment_configure.md#target-node-operating-system-support) for details on supported Operating System targets with Ansible.

> [!note]
> Changing the `source_image_reference` setting after deployment typically would trigger every node to be rebuilt. For this reason, the Terraform modules in the Toolkit have been explicitly configured to ignore any changes once deployed. It's recommended to upgrade the OS via it's standard process, for more information refer to [this section](environment_upgrades.md#avoid-changing-machine-os-image).

```tf
module "gitlab_ref_arch_azure" {
  source = "../../modules/gitlab_ref_arch_azure"

  source_image_reference = {
    "publisher" = "Canonical"
    "offer"     = "ubuntu-24_04-lts"
    "sku"       = "server"
    "version"   = "latest"
  }

  [...]
}
```

##### Configure network setup (Azure)

The module for Azure will handle the networking by default by setting up the infrastructure on the default network stack as provided by Azure. It's possible to adjust network rules if needed. To learn more refer to [Configuring Network CIDR Access](environment_advanced_network.md#configuring-network-cidr-access).

#### Configure Authentication (Azure)

Finally, the last thing to configure is authentication. This is required to allow Terraform to access Azure (provider) as well as its State Storage Bucket (backend).

Terraform provides multiple ways to authenticate with the [provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#authenticating-to-azure) and [backend](https://developer.hashicorp.com/terraform/language/backend/azurerm), you can select any method that is desired.

If you are planning to run the toolkit locally, use [Azure CLI](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/azure_cli) authentication method. Otherwise, you can use either a Service Principal or Managed Service Identity when running Terraform non-interactively. Refer to [Authenticating to Azure](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#authenticating-to-azure) documentation for details. Once you have selected the authentication method and obtained the credentials you may export them as Environment Variables following the Terraform instructions for the specific authentication type to fully authenticate for both the provider and backend.

### Sensitive variable handling in Terraform

There may be times when you have to pass in sensitive variables in the Terraform modules, such as passwords for [Cloud Services](environment_advanced_services.md).

The Toolkit has been designed to be open in terms of sensitive variables as there are various strategies that could be used to secure them depending on your preferences. As long as the variables are configured in Terraform at runtime the Toolkit isn't concerned where they come from.

Some of these strategies are Environment Variables and [Terraform Data Sources](https://developer.hashicorp.com/terraform/language/data-sources), the latter being able to pull in variables from various sources such as Secret Managers.

Below are some examples of select sources that are well suited to this.

#### Environment Variables

[Terraform can read any Environment Variable on the machine running it](https://developer.hashicorp.com/terraform/cli/config/environment-variables#tf_var_name) with the prefix `TF_VAR_*`.

Terraform will treat all `TF_VAR_*` environment variables as variables, and you can set those in your config as desired. This is ideal for sensitive variables and in CI for overriding any variables as desired.

As an example, on an AWS environment, if you wanted to set the `ssh_public_key_file` variable via an Environment Variable you would just set `TF_VAR_ssh_public_key_file` and run as normal.

#### Terraform Data Sources

Terraform has multiple [Data Sources](https://developer.hashicorp.com/terraform/language/data-sources) available depending on the cloud provider that you can utilize to pull in variables from other sources, such as Secret Managers.

As the Terraform config files you've configured are normal Terraform files, you can configure Data Sources to first collect variables and then pass them into the Toolkit's modules.

As an example, on an AWS environment, if you wanted to set the `ssh_public_key` variable via a JSON Key-Value secret that's named the same with a key also under the same name on [AWS Secret Manager](https://aws.amazon.com/secrets-manager/) you would use the [`aws_secretsmanager_secret_version` data source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) as follows:

```tf
data "aws_secretsmanager_secret_version" "ssh_public_key" {
  secret_id = "ssh_public_key"
}

module "gitlab_ref_arch_aws" {
  source = "../../modules/gitlab_ref_arch_aws"

  prefix = var.prefix
  ssh_public_key = jsondecode(aws_secretsmanager_secret_version.ssh_public_key.secret_string)["ssh_public_key"]
[...]
}
```

Any Terraform Data Source can be used similarly. Refer to the specific Data Source docs for more info.

### Config Examples

[Full config examples are available for select Reference Architectures](../examples). The rest of this section will describe what the config does and how to use it.

## 4. Run the GitLab Environment Toolkit's Docker container (optional)

Before running the [Docker container](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/container_registry/2697240) you will need to set up your environment config files by following [# 2. Set up the Environment's config](#3-set-up-the-environments-config). The container can be started once the Terraform config has been set up. When starting the container it is important to pass in your config files and keys, as well as set any authentication based environment variables.

Below is an example of how to run the container when using a GCP service account:

```sh
docker run -it \
  -e GOOGLE_APPLICATION_CREDENTIALS="/gitlab-environment-toolkit/keys/<service account file>" \
  -v <path to keys directory>:/gitlab-environment-toolkit/keys \
  -v <path to Terraform config>:/gitlab-environment-toolkit/terraform/environments/<environment name> \
  registry.gitlab.com/gitlab-org/gitlab-environment-toolkit:latest
```

You can also use a simplified command if you store your config outside the toolkit. Using the folder structure below you're able to store multiple environments alongside each other and when using the Toolkit's container you can simply pass in a single folder and still have access to all your different environments.

```sh
get_environments
├──keys
└──<environment name>
|  └──terraform
|     ├── environment.tf
|     ├── main.tf
|     └── variables.tf
└──<environment name>
   └──terraform
```

```sh
docker run -it \
  -e GOOGLE_APPLICATION_CREDENTIALS="/gitlab-environment-toolkit/keys/<service account file>" \
  -v <path to `get_environments` directory>:/environments \
  registry.gitlab.com/gitlab-org/gitlab-environment-toolkit:latest
```

### Install Terraform in Docker container

After starting the container you will need to install the specific version of Terraform required for your environment.

Terraform is not installed by default due to licensing reasons. However, [`mise`](https://mise.jdx.dev/) and a compatible Terraform plugin are provided in the image already for convenience. Refer to the [Install Terraform using `mise` or `asdf`](#install-terraform-using-mise-or-asdf) section on how to use `mise` to install Terraform.

## 5. Provision

After the config has been set up you're now ready to provision the environment. This is done as follows:

1. Change to the Terraform directory under the `gitlab-environment-toolkit` directory:

    ```sh
    cd terraform/environments/<ENV_NAME>
    ```

1. Run `terraform init` to initialize Terraform and perform required preparation such as downloading required providers. This typically only needs to be run once for the first build or after any notable config changes:

    ```sh
    terraform init
    ```

1. Run `terraform apply` to actually provision the infrastructure, a confirmation prompt will be shown by Terraform before proceeding:

    ```sh
    terraform apply
    ```

## Next Steps

After the above steps have been completed you can proceed to [Configuring the environment with Ansible](environment_configure.md).
