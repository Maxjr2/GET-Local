# Quick Start Guide

- [**GitLab Environment Toolkit - Quick Start Guide**](environment_quick_start_guide.md)
- [GitLab Environment Toolkit - Preparing the environment provider](environment_prep.md)
- [GitLab Environment Toolkit - Provisioning the environment with Terraform](environment_provision.md)
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

On this page you'll find a Quick Start Guide where we go through the steps with examples on how to set up a GitLab environment required with the Toolkit.

For the purpose of this guide we'll go through the steps required for a [1k Reference Architecture](https://docs.gitlab.com/ee/administration/reference_architectures/1k_users.html) on Nutanix AHV. This will be done by running the Toolkit natively from source via a Git checkout.

> [!note]
> This quick guide won't cover all the potential options available and assumes a good working knowledge of Terraform, Ansible and GitLab. It's recommended you still read the docs in full to ensure the environment is configured as per your requirements.

[TOC]

## Prerequisites

Before starting the quick guide there are some prerequisites you should go through below.

> [!note]
> Any variable values in this guide with surrounding `<>` brackets indicates that they should be replaced.

### Select an Environment Name

The Toolkit needs an appropriate environment name for it to name all the infrastructure accordingly. This should be something short and unique.

> [!note]
> This will be referred to as `<ENV_NAME>` later in this guide.

### Gather Nutanix Details

You'll also need access to a Prism Central instance along with the UUIDs of the pre-existing cluster, subnet, base OS image and storage container to deploy into - see the [Nutanix section](environment_prep.md#nutanix) of Preparing the environment for what to gather.

> [!note]
> These will be referred to as `<PRISM_CENTRAL_ENDPOINT>`, `<NUTANIX_USERNAME>`, `<NUTANIX_PASSWORD>`, `<CLUSTER_UUID>`, `<SUBNET_UUID>`, `<IMAGE_UUID>` and `<STORAGE_CONTAINER_UUID>` later in this guide.

### Select Passwords and Tokens

There are various passwords and tokens to be set for GitLab. Later on in the guide you'll be asked to fill these in with any values you desire. You can generate these now or later accordingly.

> [!note]
> Passwords will be referred to as `<*_PASSWORD>` and `<*_TOKEN>` respectively later in this guide.

## 1. Preparing the environment

The first step is to [prepare the environment](environment_prep.md). This includes setting up an SSH key and gathering the Nutanix details above.

### 1a. SSH Key

We need an SSH key to be configured on the machines to allow Ansible access directly to the boxes.

Generating the key itself is as normal and covered in the main [GitLab docs](https://docs.gitlab.com/ee/user/ssh.html#generate-an-ssh-key-pair) (ED25519 recommended). Name the public and private keys as desired and copy them to `gitlab-environment-toolkit/keys`.

> [!note]
> The public SSH file name will be referred to as `<SSH_PUBLIC_KEY_FILE_NAME>` and private `<SSH_PRIVATE_KEY_FILE_NAME>` later in this guide.

### 1b. Terraform State Storage

Next we need a place to save the Terraform State file. It's recommended this is in a remote location as this allows all users ensure they're on the same state - see [GitLab's own managed Terraform State backend](https://docs.gitlab.com/ee/user/infrastructure/iac/terraform_state.html) as an option, or any other [Terraform backend](https://developer.hashicorp.com/terraform/language/state/remote-state-data). For this guide we'll use the `local` backend for simplicity, which requires no additional setup.

## 2. Provisioning the environment with Terraform

With the prep done [we're now ready to set up the config for Terraform to provision](environment_provision.md) the environment's infrastructure on Nutanix AHV. This involves installing Terraform, setting up the config and then running Terraform.

Let's go through the steps for each.

Config is recommended to be placed in a new folder named after the environment under the `gitlab-environment-toolkit/terraform/environments` folder, e.g. `gitlab-environment-toolkit/terraform/environments/<ENV_NAME>`.

> [!note]
> For the purposes of this guide we're running the Toolkit natively from source where the modules are all available on disk.

### 2a. Installing Terraform with `mise`

First we need to install Terraform. To easily switch between Terraform versions we recommend installing with [`mise`](https://github.com/jdx/mise) as follows:

1. Install `mise` as per its [documentation](https://mise.jdx.dev/getting-started.html)
1. In the Toolkit directory, install the default version of Terraform by first adding its plugin and then installing:

    ```sh
    mise install terraform -y
    ```

> [!note]
> The version of Terraform that's installed is set in the [`.tool-versions` file](../.tool-versions). Other versions can be installed as required.

Terraform should now be installed and ready on your `PATH`.

### 2b. Setup Config

Now we'll set up the Terraform config for the environment. There are 3 config files to configure - Variables (`variables.tf`), Main (`main.tf`) and Environment (`environment.tf`) - as follows:

First is the Variables file, which contains some variables to be used by Terraform for connecting to Nutanix as well as setting some environment basics:

<details><summary>Variables - <code>gitlab-environment-toolkit/terraform/environments/&#60;ENV_NAME&#62;/variables.tf</code></summary>

```tf
variable "prefix" {
  default = "<ENV_NAME>"
}

variable "nutanix_endpoint" {
  default = "<PRISM_CENTRAL_ENDPOINT>"
}

variable "nutanix_username" {
  default = "<NUTANIX_USERNAME>"
}

variable "nutanix_password" {
  default = "<NUTANIX_PASSWORD>"
}

variable "cluster_uuid" {
  default = "<CLUSTER_UUID>"
}

variable "subnet_uuid" {
  default = "<SUBNET_UUID>"
}

variable "image_uuid" {
  default = "<IMAGE_UUID>"
}

variable "storage_container_uuid" {
  default = "<STORAGE_CONTAINER_UUID>"
}

variable "vm_admin_username" {
  default = "gitlab"
}

variable "ssh_public_key_file_path" {
  default = "../../../keys/<SSH_PUBLIC_KEY_FILE_NAME>"
}
```

</details>

Next is the Main file, which configures Terraform how to authenticate against Nutanix and where to save its state:

<details><summary>Main - <code>gitlab-environment-toolkit/terraform/environments/&#60;ENV_NAME&#62;/main.tf</code></summary>

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

</details>

Finally, we have the Environment file, which configures the Toolkit's modules on how to actually build the environment:

<details><summary>Environment - <code>gitlab-environment-toolkit/terraform/environments/&#60;ENV_NAME&#62;/environment.tf</code></summary>

```tf
module "gitlab_ref_arch_nutanix" {
  source = "../../modules/gitlab_ref_arch_nutanix"

  prefix                 = var.prefix
  cluster_uuid           = var.cluster_uuid
  subnet_uuid            = var.subnet_uuid
  image_uuid             = var.image_uuid
  storage_container_uuid = var.storage_container_uuid
  vm_admin_username      = var.vm_admin_username
  ssh_public_key         = file(var.ssh_public_key_file_path)

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

</details>

With the above config in place we should now be ready to run Terraform.

### 2c. Provision

The machines and infrastructure are now ready to be provisioned with Terraform. This is done via a few commands as follows:

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

After Terraform has finished running, the machines and other infrastructure will now be provisioned.

## 3. Configuring the environment with Ansible

With the machines and infrastructure provisioned, we're now ready to [set up Ansible to configure GitLab](environment_configure.md). This involves installing Ansible, setting up the config and then running Ansible.

Let's go through the steps for each.

Config is recommended to be placed in a new folder named after the environment under the `gitlab-environment-toolkit/ansible/environments/` folder, e.g. `gitlab-environment-toolkit/ansible/environments/<ENV_NAME>/inventory`.

> [!note]
> For the purposes of this guide we're running the Toolkit natively from source where the playbooks and roles are all available on disk.

### 3a. Installing Ansible with a Virtual Environment

First we need to install Ansible. There are various ways to install Ansible, we recommend using Python in a Virtual Environment. Once installed we also need to install some Python and Ansible packages. The steps for all of this are as follows:

1. Create a virtual environment called `get-python-env` in the `gitlab-environment-toolkit` directory and activate it:

    ```sh
    python3 -m venv get-python-env
    . ./get-python-env/bin/activate
    ```

1. Install Ansible, and it's required Python packages via pip:

    ```sh
    pip3 install -r ansible/requirements/requirements.txt
    ```

1. Install Ansible Galaxy Collections and Roles:

    ```sh
    ansible-galaxy install -r ansible/requirements/ansible-galaxy-requirements.yml --force
    ```

1. Install OpenSSH Client if not already installed as per your OS.

> [!note]
> If you're on a macOS machine you'll also need to install `gnu-tar` by running `brew install gnu-tar`

### 3b. Setup Config

Now we'll set up the Ansible config for the environment. There are 2 config files to configure - Dynamic Inventory (`<ENV_NAME>.nutanix.yml`) and Environment (`vars.yml`) - as follows:

> [!tip]
> Some of the config we set here matches config set in Terraform.

First is the Dynamic Inventory file, which configures Ansible to retrieve the machine list from Prism Central and their details:

<details><summary>Dynamic Inventory - <code>gitlab-environment-toolkit/ansible/environments/&#60;ENV_NAME&#62;/inventory/ENV_NAME.nutanix.yml</code></summary>

> [!note]
> Only values in `<>` brackets should be changed in this file and the rest should match. It also must be saved with the suffix `nutanix.yml`.

```yaml
plugin: nutanix.ncp.ntnx_prism_vm_inventory_v2

pc_hostname: "<PRISM_CENTRAL_ENDPOINT>"
pc_username: "<NUTANIX_USERNAME>"
pc_password: "<NUTANIX_PASSWORD>"
pc_port: 9440
validate_certs: false

filters:
  category_key: "gitlab_node_prefix"
  category_value: "<ENV_NAME>"

keyed_groups:
  - prefix: ''
    separator: ''
    key: categories.gitlab_node_type | default('ungrouped')
  - prefix: ''
    separator: ''
    key: categories.gitlab_node_level | default('ungrouped')

compose:
  ansible_host: nics[0].ip_addresses[0]
```

</details>

Next is the Environment config file that contains all the config for configuring GitLab:

<details><summary>Environment - <code>gitlab-environment-toolkit/ansible/environments/&#60;ENV_NAME&#62;/inventory/vars.yml</code></summary>

> [!note]
> [As mentioned earlier in this guide](#select-passwords-and-tokens) all `<*_PASSWORD>` and `<*_TOKEN>` entries should be replaced with your own.

```yaml
all:
  vars:
    # Ansible Settings
    ansible_user: "gitlab"
    ansible_ssh_private_key_file: "{{ lookup('env', 'PWD') }}/../keys/<SSH_PRIVATE_KEY_FILE_NAME>"

    # Cloud Settings, available options: nutanix, none
    cloud_provider: "nutanix"

    # General Settings
    prefix: "<ENV_NAME>"
    external_url: "http://<EXTERNAL_IP_OR_HOSTNAME>"

    # Passwords / Secrets (Replace values accordingly)
    gitlab_root_password: '<GITLAB_ROOT_PASSWORD>'
    postgres_password: '<POSTGRES_PASSWORD>'
    consul_database_password: '<CONSUL_DATABASE_PASSWORD>'
    gitaly_token: '<GITALY_TOKEN>'
    pgbouncer_password: '<PGBOUNCER_PASSWORD>'
    redis_password: '<REDIS_PASSWORD>'
    praefect_external_token: '<PRAEFECT_EXTERNAL_TOKEN>'
    praefect_internal_token: '<PRAEFECT_INTERNAL_TOKEN>'
    praefect_postgres_password: '<PRAEFECT_POSTGRES_PASSWORD>'
```

</details>

### 3c. Configure

GitLab is now ready to be configured with Ansible. This is done via a few commands as follows:

1. Change to the Ansible directory - `cd ansible` in the `gitlab-environment-toolkit` directory.
1. Run `ansible-playbook -i environments/<ENV_NAME>/inventory playbooks/all.yml` to run through all the playbooks and configure GitLab.

After Ansible has finished running, GitLab will now be configured and the environment ready to go.

## Config Examples

[Full config examples are available for select Reference Architectures](../examples).

## Steps after deployment

With the above steps completed you should now have a running environment. Head to the external address you've configured and try logging in to check.

Next you should consider any [advanced setups](environment_advanced.md) you may wish to explore, the notes on [Upgrades](environment_upgrades.md) as well as reading through the [considerations after deployment](environment_post_considerations.md) such as backups and security.

## Troubleshooting

If you encounter any errors in this process, the [Troubleshooting](environment_troubleshooting.md) page contains further guidance on various common errors seen and how to address them.
