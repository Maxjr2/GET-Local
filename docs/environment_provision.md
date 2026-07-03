# Provisioning the environment with Terraform

- [GitLab Environment Toolkit - Quick Start Guide](environment_quick_start_guide.md)
- [GitLab Environment Toolkit - Preparing the environment](environment_prep.md)
- [**GitLab Environment Toolkit - Provisioning the environment with Terraform**](environment_provision.md)
- [GitLab Environment Toolkit - Configuring the environment with Ansible](environment_configure.md)
- [GitLab Environment Toolkit - Advanced - Custom Config / Tasks / Files, Data Disks, Advanced Search, Container Registry and more](environment_advanced.md)
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

For example, to configure the `gitlab_ref_arch_nutanix` module using a relative path that follows this repo's structure you would configure it follows:

```tf
module "gitlab_ref_arch_nutanix" {
  source = "../../modules/gitlab_ref_arch_nutanix"

  [...]
}
```

### Git URL

Terraform can also pull the Modules directly from this repo via a [Git URL](https://developer.hashicorp.com/terraform/language/block/module#git-repository).

For example, to configure the `gitlab_ref_arch_nutanix` module to pull from the repo you would configure it follows:

```tf
module "gitlab_ref_arch_nutanix" {
  source = "git::https://gitlab.com/gitlab-org/gitlab-environment-toolkit.git//modules/gitlab_ref_arch_nutanix"

  [...]
}
```

### Terraform Module Registry

The Toolkit's Modules are also made available via this Project's [Terraform Module Registry](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/infrastructure_registry).

For example, to configure the `gitlab_ref_arch_nutanix` module to pull from the registry you would configure it follows:

```tf
module "gitlab_ref_arch_nutanix" {
  source = "gitlab.com/gitlab-org/gitlab-environment-toolkit/gitlab//modules/gitlab_ref_arch_nutanix"
  version = ">= 3.0.0"

  [...]
}
```

Note the `version` setting here [can be changed as desired to any constraint](https://developer.hashicorp.com/terraform/language/expressions/version-constraints#version-constraint-syntax) that's `2.0.0` or greater.

## 3. Set up the Environment's config

As mentioned the Toolkit provides several [Terraform Modules](../terraform/modules) that can be used to provision the environment as per the [Reference Architectures](https://docs.gitlab.com/ee/administration/reference_architectures/). While there are several modules provided with the Toolkit most of these are under the hood. For most users only one easy to use `ref_arch` module will need to be configured.

The `ref_arch` modules configure not only the VMs required for the environment but also things such as networking, labels for Ansible to use and more. This fork provides one `ref_arch` module, for Nutanix AHV, and there are 3 config files to set up:

- `main.tf` - Contains the main Terraform connection settings such as cloud provider or state backend.
- `environment.tf` - `ref_arch` module configuration (machine count or sizes for example).
- `variables.tf` - Variable definitions.

Each of the above files must be set in the same folder for Terraform to merge. Due to relative path requirements in Terraform we recommend you create these in a unique folder for your environment under the provided [`terraform/environments` folder](../terraform/environments), e.g. `terraform/environments/<env_name>`. This documentation will assume this is the case from now on.

This fork of the Toolkit supports two deployment targets: Nutanix AHV via Terraform, or on-prem/custom servers configured directly via Ansible static inventory (see [Configuring the environment with Ansible](environment_configure.md), which requires no Terraform provisioning step at all). This section covers the Nutanix Terraform setup - if you're using static inventory against existing servers, you can skip ahead to [Configuring the environment with Ansible](environment_configure.md).

### Nutanix

> [!warning]
> Nutanix support is a self-maintained addition to this fork of the Toolkit. See the [Supported Cloud Providers](../TECHNICAL_DESIGN.md#supported-cloud-providers) section for scope and support expectations. It has not been validated end-to-end against a live Nutanix cluster.

The module for setting up a full GitLab Reference architecture on Nutanix AHV is **`gitlab_ref_arch_nutanix`** (`terraform/modules/gitlab_ref_arch_nutanix`). It provisions VMs via the [`nutanix/nutanix`](https://registry.terraform.io/providers/nutanix/nutanix/latest) provider against a Prism Central endpoint.

This module does not create the underlying cluster, subnet, storage container or base OS image — these are expected to already exist in Prism Central, and are passed in as UUIDs. It also does not manage external/public IPs (Nutanix AHV has no equivalent resource); external access to HAProxy/GitLab Rails nodes must be handled by your existing network/VLAN routing.

#### Configure Variables (`variables.tf`)

```tf
variable "prefix" {
  default = "<environment_prefix>"
}

variable "nutanix_endpoint" {
  default = "<prism_central_endpoint>"
}

variable "nutanix_username" {
  default = "<nutanix_username>"
}

variable "nutanix_password" {
  default = "<nutanix_password>"
}

variable "cluster_uuid" {
  default = "<nutanix_cluster_uuid>"
}

variable "subnet_uuid" {
  default = "<nutanix_subnet_uuid>"
}

variable "image_uuid" {
  default = "<nutanix_image_uuid>"
}

variable "storage_container_uuid" {
  default = "<nutanix_storage_container_uuid>"
}

variable "vm_admin_username" {
  default = "<vm_admin_username>"
}

variable "ssh_public_key_file_path" {
  default = "<ssh_public_key_file_path>"
}
```

- `prefix` - Used to set the names and Nutanix categories of the VMs consistently. Once set, do not change.
- `nutanix_endpoint` / `nutanix_username` / `nutanix_password` - Connection details for your Prism Central instance.
- `cluster_uuid` - UUID of the target Nutanix AHV cluster.
- `subnet_uuid` - UUID of the pre-existing subnet/VLAN the VMs should attach to.
- `image_uuid` - UUID of the pre-existing base OS image (e.g. an Ubuntu 24.04 cloud image) VMs should be cloned from.
- `storage_container_uuid` - UUID of the storage container used for boot and data disks.
- `vm_admin_username` / `ssh_public_key_file_path` - The admin user and SSH public key injected into VMs via cloud-init.

#### Configure Terraform settings (`main.tf`)

```tf
terraform {
  backend "local" {}

  required_providers {
    nutanix = {
      source  = "nutanix/nutanix"
      version = "~> 2.4"
    }
  }
}

provider "nutanix" {
  endpoint = var.nutanix_endpoint
  username = var.nutanix_username
  password = var.nutanix_password
  insecure = false
}
```

Swap the `local` backend for a remote one (e.g. `s3`, `azurerm`, `gcs`) for anything beyond a single local trial.

#### Configure Module settings (`environment.tf`)

Sizing follows the [Reference Architectures](https://docs.gitlab.com/ee/administration/reference_architectures/) — set the `*_node_count` and `*_size` variables for the components you need. `*_size` is an object instead of a named SKU string, since Nutanix has no named machine sizes:

```tf
module "gitlab_ref_arch_nutanix" {
  source = "../../modules/gitlab_ref_arch_nutanix"

  prefix                  = var.prefix
  cluster_uuid            = var.cluster_uuid
  subnet_uuid             = var.subnet_uuid
  image_uuid              = var.image_uuid
  storage_container_uuid  = var.storage_container_uuid
  vm_admin_username       = var.vm_admin_username
  ssh_public_key          = file(var.ssh_public_key_file_path)

  # 1k
  gitlab_rails_node_count = 1
  gitlab_rails_size = {
    num_sockets          = 4
    num_vcpus_per_socket = 2
    memory_size_mib      = 8192
  }
}

output "gitlab_ref_arch_nutanix" {
  value = module.gitlab_ref_arch_nutanix
}
```

- `*_node_count` - The number of machines to set up for that component.
- `*_size` - Object with `num_sockets`, `num_vcpus_per_socket` and `memory_size_mib`. Falls back to `default_size` if unset.
- `*_disk_size` - Boot disk size in GB. For Gitaly this defaults to `4095`; other components fall back to `default_disk_size` (`100`).
- `*_data_disks` - Optional list of extra disks (`name`, `size`, `storage_container_uuid`, `index`).

> [!note]
> Redis prefixes depend on the target Reference Architecture - set `redis_*` for combined Redis, `redis_cache_*` and `redis_persistent_*` for separated Redis setup.

Object Storage is not provisioned by this module - Nutanix Objects buckets (or any S3-compatible store) must be created out of band and configured via [Custom Config](environment_advanced.md#custom-config), the same fallback documented for [Custom Servers (On Prem)](environment_advanced.md#custom-servers-on-prem).

Tagging for Ansible dynamic inventory grouping is done via Nutanix categories (`gitlab_node_prefix`, `gitlab_node_type`, `gitlab_node_level`) rather than free-form tags — the module creates the required category keys/values itself, since Nutanix requires category values to be pre-registered before they can be attached to a VM.

#### Configure Authentication (Nutanix)

Authentication to Prism Central is via `username`/`password` on the `nutanix` provider block (or the `NUTANIX_USERNAME`/`NUTANIX_PASSWORD`/`NUTANIX_ENDPOINT` environment variables). See the [provider documentation](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs) for other authentication options (e.g. `api_key`).

### Sensitive variable handling in Terraform

There may be times when you have to pass in sensitive variables in the Terraform modules, such as the Nutanix Prism Central `nutanix_password` variable.

The Toolkit has been designed to be open in terms of sensitive variables as there are various strategies that could be used to secure them depending on your preferences. As long as the variables are configured in Terraform at runtime the Toolkit isn't concerned where they come from.

Some of these strategies are Environment Variables and [Terraform Data Sources](https://developer.hashicorp.com/terraform/language/data-sources), the latter being able to pull in variables from various sources such as Secret Managers.

Below are some examples of select sources that are well suited to this.

#### Environment Variables

[Terraform can read any Environment Variable on the machine running it](https://developer.hashicorp.com/terraform/cli/config/environment-variables#tf_var_name) with the prefix `TF_VAR_*`.

Terraform will treat all `TF_VAR_*` environment variables as variables, and you can set those in your config as desired. This is ideal for sensitive variables and in CI for overriding any variables as desired.

As an example, if you wanted to set the `nutanix_password` variable via an Environment Variable you would just set `TF_VAR_nutanix_password` and run as normal.

#### Terraform Data Sources

Terraform has multiple [Data Sources](https://developer.hashicorp.com/terraform/language/data-sources) available that you can utilize to pull in variables from other sources, such as Secret Managers.

As the Terraform config files you've configured are normal Terraform files, you can configure Data Sources to first collect variables and then pass them into the Toolkit's modules.

As an example, if you wanted to set the `nutanix_password` variable via a JSON Key-Value secret stored in a Secret Manager, you would use the corresponding Terraform provider's secret data source, decode the value, and pass it into the module, e.g.:

```tf
data "vault_generic_secret" "nutanix_password" {
  path = "secret/nutanix_password"
}

module "gitlab_ref_arch_nutanix" {
  source = "../../modules/gitlab_ref_arch_nutanix"

  prefix = var.prefix
  nutanix_password = data.vault_generic_secret.nutanix_password.data["nutanix_password"]
[...]
}
```

Any Terraform Data Source can be used similarly. Refer to the specific Data Source docs for more info.

### Config Examples

[Full config examples are available for select Reference Architectures](../examples). The rest of this section will describe what the config does and how to use it.

## 4. Run the GitLab Environment Toolkit's Docker container (optional)

Before running the [Docker container](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/container_registry/2697240) you will need to set up your environment config files by following [# 2. Set up the Environment's config](#3-set-up-the-environments-config). The container can be started once the Terraform config has been set up. When starting the container it is important to pass in your config files and keys, as well as set any authentication based environment variables.

Below is an example of how to run the container, passing in Nutanix authentication as environment variables:

```sh
docker run -it \
  -e TF_VAR_nutanix_password="<nutanix_password>" \
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
  -e TF_VAR_nutanix_password="<nutanix_password>" \
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
