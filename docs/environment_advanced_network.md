# Advanced - Network Setup

- [GitLab Environment Toolkit - Quick Start Guide](environment_quick_start_guide.md)
- [GitLab Environment Toolkit - Preparing the environment](environment_prep.md)
- [GitLab Environment Toolkit - Provisioning the environment with Terraform](environment_provision.md)
- [GitLab Environment Toolkit - Configuring the environment with Ansible](environment_configure.md)
- [GitLab Environment Toolkit - Advanced - Custom Config / Tasks / Files, Data Disks, Advanced Search, Container Registry and more](environment_advanced.md)
- [GitLab Environment Toolkit - Advanced - Cloud Native Hybrid](environment_advanced_hybrid.md)
- [GitLab Environment Toolkit - Advanced - Component Cloud Services / Custom (Load Balancers, PostgreSQL, Redis)](environment_advanced_services.md)
- [GitLab Environment Toolkit - Advanced - SSL](environment_advanced_ssl.md)
- [**GitLab Environment Toolkit - Advanced - Network Setup**](environment_advanced_network.md)
- [GitLab Environment Toolkit - Advanced - Monitoring](environment_advanced_monitoring.md)
- [GitLab Environment Toolkit - Upgrades (Toolkit, Environment)](environment_upgrades.md)
- [GitLab Environment Toolkit - Considerations After Deployment - Backups, Security](environment_post_considerations.md)
- [GitLab Environment Toolkit - Geo](geo/README.md)
  - [GitLab Environment Toolkit - Geo - Provisioning the environment with Terraform](geo/geo_provision.md)
  - [GitLab Environment Toolkit - Geo - Configuring the environment with Ansible](geo/geo_configure.md)
  - [GitLab Environment Toolkit - Geo - Advanced](geo/geo_advanced.md)
- [GitLab Environment Toolkit - Troubleshooting](environment_troubleshooting.md)

By default, the Toolkit will configure network setup using the default cloud provider's network. However, it can also support other advanced setups on select cloud providers such as creating a new network or using an existing one.

On this page we'll detail all the supported advanced setups you can do with the Toolkit. We recommend you only do these setups if you have a good working knowledge of both the Toolkit and what the specific setups involve.

[TOC]

## Configure network setup (GCP)

The module for GCP can configure the [network stack](https://cloud.google.com/vpc/docs/vpc) (For example VPC or Subnets) for your environment in several ways:

- **Default** - Sets up the infrastructure on the default network stack as provided by GCP. This is the default for the module.
- **Created** - Creates the required network stack for the infrastructure.
- **Existing** - Will use a provided network stack passed in by the user.

In this section you will find the config required to set up each depending on your requirements.

> [!warning]
> You should not change the network type on an existing environment. This will typically trigger a total environment rebuild and result in downtime and data loss.

### Default (GCP)

This is the default setup for the module and is the recommended setup for most standard (Omnibus) environments where GCP will handle the networking by default.

No additional configuration is needed to use this setup.

To lock down network access to particular CIDR blocks follow [Configuring Network CIDR Access](#configuring-network-cidr-access) guidance.

### Created (GCP)

When configured the module will create a network stack to run the environment in. The network stack created is as follows:

- 1 VPC
- 1 Subnet
- Firewall rules to allow for required network connections

The environment's machines will be created in the created subnet.

This setup is recommended for users who want a specific network stack for their GitLab environment.

To configure this setup the following config should be added to the [module's environment config file](environment_provision.md#configure-module-settings-environmenttf):

- `create_network` - This variable should be set to `true` when you are wanting the module to create a new network stack.

An example of your environment config file then would look like:

```tf
module "gitlab_ref_arch_gcp" {
  source = "../../modules/gitlab_ref_arch_gcp"

  prefix = var.prefix
  project = var.project

  create_network = true

  [...]
```

In addition to the above the following _optional_ settings change how the network is configured:

- `create_network_subnet_cidr_block`- A [CIDR block](https://cloud.google.com/vpc/docs/vpc#manually_created_subnet_ip_ranges) that will be used for the created subnet. This shouldn't need to be changed in most scenarios unless you want to use a specific CIDR blocks. Default is `"10.86.0.0/16"`

### Existing (GCP)

For this advanced setup, you must have an existing network stack for the environment to use that meets the following requirements:

- An existing VPC in the target project
- That the VPC has subnets in the desired regions

> [!note]
> When configured, the module will set up several GCP Firewall rules in the VPC to enable the correct network for the GitLab environment depending on the setup.

To configure this setup the following config should be added to the [module's environment config file](environment_provision.md#configure-module-settings-environmenttf):

- `vpc_name` - The name of your existing VPC.
- `subnet_name` - The name of your existing Subnet. The subnet should be located in the same existing VPC.

An example of your environment config file then would look like:

```tf
module "gitlab_ref_arch_gcp" {
  source = "../../modules/gitlab_ref_arch_gcp"

  prefix = var.prefix
  project = var.project

  vpc_name = "<vpc-name>"
  subnet_name = "<subnet-name>"

  [...]
}
```

### Disable External IPs (GCP)

On any of the network types above it's also possible to disable GCP provisioning external IPs for any VMs.

This is done in Terraform with the `setup_external_ips` variable being set to false in your `environment.tf` file.

**GCP**

```tf
module "gitlab_ref_arch_gcp" {
  source = "../../modules/gitlab_ref_arch_gcp"
[...]

  setup_external_ips = false
}
```

Once set, no external IPs will be created or added to your nodes.

In this setup however some tweaks will need to be made to Ansible:

- It will need to be run from a box that can access the boxes via internal IPs
- The `external_url` setting should be set to the URL that the instance will be reachable internally
- When using the Dynamic Inventory it will need to be adjusted to return internal IPs. This can be done by changing the `compose.ansible_host` setting to `private_ip_address`

### Cloud IAP SSH access (GCP)

The Toolkit allows for enabling [GCP Cloud Identity-Aware Proxy (IAP)](https://cloud.google.com/iap/docs/using-tcp-forwarding) access to nodes, both Linux package and GKE VMs, as desired.

Specifically it can create the required Firewall rules for IAP tunnels to connect via the following setting in your Terraform `environment.tf` file:

- `setup_iap_ssh_access` - Configures firewall rule(s) to allow GCP IAP tunnel access to Linux package and GKE nodes.

> [!note]
> Additional user permissions may be required to connect to nodes via IAP. Refer to the [GCP documentation](https://cloud.google.com/iap/docs/using-tcp-forwarding#grant-permission) for more information.

## Configure network setup (AWS)

By default, the toolkit sets up the infrastructure on the default network stack as provided by AWS. However, it can also support other advanced setups such as creating a new network or using an existing one.

The module for AWS can configure the [network stack](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html) (For example VPC or Subnets) for your environment in several ways:

- **Default** - Sets up the infrastructure on the default network stack as provided by AWS. This is the default for the module.
- **Created** - Creates the required network stack for the infrastructure
- **Existing** - Will use a provided network stack passed in by the user

Additionally, for the Created and Existing network types above you can configure the subnets used to be private or public.

In this section you will find the config required to set up each depending on your requirements.

> [!warning]
> You should not change the network type on an existing environment. This will typically trigger a total environment rebuild and result in downtime and data loss.

### Default (AWS)

This is the default setup for the module where AWS will handle the networking by default. No additional configuration is needed to use this setup.

To lock down network access to particular CIDR blocks follow [Configuring Network CIDR Access](#configuring-network-cidr-access) guidance.

### Created (AWS)

When configured the module will create a network stack to run the environment in. The network stack created is as follows:

- 1 VPC
- 2 Subnets are created in the created VPC and are additionally spread across the available Availability Zones in the selected region.
  - The number of Subnets is configurable.
- 1 Internet Gateway
- 1 Route Table

The environment's machines will be spread across the created subnets and their Availability Zones evenly.

This setup is recommended for users who want a specific network stack for their GitLab environment. It's also recommended for Cloud Native Hybrid environments running on AWS.

To configure this setup the following config should be added to the [module's environment config file](environment_provision.md#configure-module-settings-environmenttf):

- `create_network` - This variable should be set to `true` when you are wanting the module to create a new network stack.

An example of your environment config file then would look like:

```tf
module "gitlab_ref_arch_aws" {
  source = "../../modules/gitlab_ref_arch_aws"

  prefix = var.prefix
  ssh_public_key = file(var.ssh_public_key_file)

  create_network = true

  [...]
```

In addition to the above the following _optional_ settings change how the network is configured:

- `vpc_cidr_block` - The [CIDR block](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html#vpc-ip-addressing) that will be used for your VPC. This shouldn't need to be changed in most scenarios unless you want to use a specific CIDR block. Default is `172.31.0.0/16`.
- `subnet_pub_count` - The number of subnets to create in the VPC. This should only be changed if you want an increased subnet count for availability reasons. Refer to the below [Created Subnet Types (Public / Private)](#created-subnet-types-public-and-private) section for more info. Default is `2`.
- `subnet_pub_cidr_block`- A list of [CIDR blocks](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html#vpc-ip-addressing) that will be used for each public subnet created. This should be changed if you want to use specific CIDR blocks. Default is `["172.31.0.0/20","172.31.16.0/20","172.31.32.0/20"]`
  - The module has up to 3 subnet CIDR blocks it will use. If you have set `subnet_pub_count` higher than 3 then this variable will need to be adjusted to match the number of subnets to be created. The CIDR blocks will need to fit in the main block defined for the VPC via `vpc_cidr_block`.
- `subnet_priv_count` - The number of private subnets to create in the VPC. This should be changed if you want more resources to be created with private subnets. Refer to the below [Created Subnet Types (Public / Private)](#created-subnet-types-public-and-private) section for more info. Default is `0`.
- `subnet_priv_cidr_block`- A list of [CIDR blocks](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html#vpc-ip-addressing) that will be used for each private subnet created. This should be changed if you want to use specific CIDR blocks. Default is `["172.31.128.0/20", "172.31.144.0/20", "172.31.160.0/20"]`
  - The module has up to 3 subnet CIDR blocks it will use. If you have set `subnet_priv_count` higher than 3 then this variable will need to be adjusted to match the number of subnets to be created. The CIDR blocks will need to fit in the main block defined for the VPC via `vpc_cidr_block`.
- `zones_exclude` - In rare cases you may need to avoid specific Availability Zones [as they don't have the available resource to deploy the infrastructure in](https://aws.amazon.com/premiumsupport/knowledge-center/eks-cluster-creation-errors/). When this is the case you can specify a list of Zones by name via this setting that will then be avoided by the Toolkit, e.g. `["us-east-1e"]`. Default is `null`.
- `availability_zones` - Availability Zones resources should be spread across. By default, (subject to `zones_exclude`) zones are  automatically chosen in the VPC by lexical order (i.e. when two subnets are requested they will be in the zones with suffixes `a`, `b`). In some circumstances (e.g. exposing services via PrivateLink to other accounts) it may be desirable to choose the Availability Zones more precisely but still allow the Toolkit to create all the resources. In these cases, you can supply the list of Zones to use. If you supply fewer zones than the number of subnets, zones will be re-used in round-robin order; if you supply more zones than the number of subnets (N), only the first N zones will be used. `zones_exclude` will _not_ be applied to this list. Default is `[]`.

#### Created Subnet Types (Public and Private)

The Toolkit supports creating both Public and Private subnets with three possible configurations based on the `subnet_pub_count` and `subnet_priv_count` settings:

- **Public Subnets Only (Default)**
  - All resources are placed in public subnets and have public IPs
  - Configuration: `subnet_pub_count` > 0 and `subnet_priv_count` = 0
- **Public + Private Subnets**
  - Most resources are placed in Private subnets except externally-facing ones (HAProxy External, EKS Cluster)
  - Configuration: `subnet_pub_count` > 0 and `subnet_priv_count` > 0
     > [!note]
     > Public and Private subnet counts must match to ensure proper [NAT Gateway](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html) configuration for Internet access
- **Private Subnets Only**
  - Fully offline environment with all resources in private subnets
  - Configuration: `subnet_pub_count` = 0 and `subnet_priv_count` > 0
  - Requires additional setup such as:
    - Private OS package repositories
    - Private network links for access

> [!note]
> When using Private subnets, most VMs won't have public IP addresses. Ansible must be run from within the network with its [Dynamic Inventory configured to use private IPs](environment_configure.md#amazon-web-services-aws) (`compose.ansible_host` set to `private_ip_address`).

### Existing (AWS)

For this advanced setup, you must have an existing network stack for the environment to use.

Ensure the network stack is configured correctly. Generally, a stack should include the same elements as listed in the **Created** section for the environment to work properly. Refer to the AWS docs for more info and specifics on how to do this.

Note that when this is configured the module will configure some AWS Security Groups in your VPC to enable network access for the environment.

With an existing stack configure the following config should be added to the [module's environment config file](environment_provision.md#configure-module-settings-environmenttf):

- `vpc_id` - The ID of your existing VPC
- `subnet_pub_ids` - A list of public subnet IDs the environment's machines should be spread across. The subnets should be located in the same existing VPC. Refer to the below [Existing Subnet Types (Public / Private)](#existing-subnet-types-public-and-private) section for more info.
- `subnet_priv_ids` - A list of private subnet IDs the environment's machines should be spread across. The subnets should be located in the same existing VPC and have any desired dependent infrastructure, e.g. NAT Gateway for internet access. Refer to the below [Existing Subnet Types (Public / Private)](#existing-subnet-types-public-and-private) section for more info.

An example of your environment config file with public subnets would look like:

```tf
module "gitlab_ref_arch_aws" {
  source = "../../modules/gitlab_ref_arch_aws"

  prefix = var.prefix
  ssh_public_key = file(var.ssh_public_key_file)

  vpc_id = "<vpc-id>"
  subnet_pub_ids = ["<public-subnet-1-id>", "<public-subnet-2-id>"]

  [...]
```

#### Existing Subnet Types (Public and Private)

When providing an existing network to the Toolkit it also supports the passthrough of public / private subnets. Like created metworks the Toolkit supports the same three possible configurations based on the `subnet_pub_count` and `subnet_priv_count` settings:

- **Public Subnets Only (Default)**
  - All resources are placed in public subnets and have public IPs
  - Configuration: `subnet_pub_count` > 0 and `subnet_priv_count` = 0
- **Public + Private Subnets**
  - Most resources are placed in Private subnets except externally-facing ones (HAProxy External, EKS Cluster)
  - Configuration: `subnet_pub_count` > 0 and `subnet_priv_count` > 0
     > [!note]
     > Public and Private subnet counts must match to ensure proper [NAT Gateway](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html) configuration for Internet access
- **Private Subnets Only**
  - Fully offline environment with all resources in private subnets
  - Configuration: `subnet_pub_count` = 0 and `subnet_priv_count` > 0
  - Requires additional setup such as:
    - Private OS package repositories
    - Private network links for access

> [!note]
> When using Private subnets, most VMs won't have public IP addresses. Ansible must be run from within the network with its [Dynamic Inventory configured to use private IPs](environment_configure.md#amazon-web-services-aws) (`compose.ansible_host` set to `private_ip_address`).

### Custom Security Groups

The Toolkit manages all the [Security Groups](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html) required for the environment.

In some advanced cases additional security group configuration may be desired depending on the setup, such as allowing access to nodes from custom load balancers or direct access to web frontends.

For these scenarios the Toolkit supports customisation of node Security groups as follows via the [module's environment config file](environment_provision.md#configure-module-settings-environmenttf):

> [!caution]
> It's recommended that these settings be used with caution as misconfigurations may result in exposed access to the selected machines unintentionally.

- `gitlab_rails_security_group_ids` - A list of additional Security Groups IDs for the GitLab Rails nodes. Optional, default is `[]`.
- `monitor_security_group_ids` - A list of additional Security Groups IDs for the Monitor node(s). Optional, default is `[]`.

### Internal Security Group Access (Default / Existing networks)

The Toolkit creates an Internal Networking security group on AWS that manages access between VPC resources (VMs, EKS Clusters) through membership. By default, resources outside this group have no access.

For advanced cases requiring internal access, such as Bastion hosts, you can configure additional access via [Security Group referencing](https://docs.aws.amazon.com/vpc/latest/userguide/security-group-rules.html#security-group-referencing). This feature is only available with Default or Existing network types.

Configure additional Security Groups for internal access using this variable in your [environment config file](environment_provision.md#configure-module-settings-environmenttf):

> [!caution]
> It's recommended that this setting be used with caution. Full Internal Networking access will be granted to all resources in the configured Security Groups.

- `internal_allowed_ingress_security_group_ids` - A list of additional Security Groups IDs to allow internal networking access to VMs or EKS Clusters. Note that the groups must be in the same VPC as the GitLab resources. Optional, default is `[]`.

## Disable External IPs (Azure)

With Azure there is only one network type available - Created. With this though it's also possible to disable provisioning external IPs for VMs if desired.

This is done in Terraform with the `setup_external_ips` variable being set to false in your `environment.tf` file.

**Azure**

```tf
module "gitlab_ref_arch_azure" {
  source = "../../modules/gitlab_ref_arch_azure"
[...]

  setup_external_ips = false
}
```

Additionally, there's the following optional settings in Terraform:

- `nat_gateway_idle_timeout_in_minutes` - TCP connections [idle timeout](https://docs.microsoft.com/en-us/azure/virtual-network/nat-gateway/nat-gateway-resource#idle-timeout-timers). Default is `4`, can be increased to up to 120 minutes.

Once set no external IPs will be created or added to your nodes.

In this setup however some tweaks will need to be made to Ansible:

- It will need to be run from a box that can access the boxes via internal IPs
- The `external_url` setting should be set to the URL that the instance will be reachable internally

## Configuring Network CIDR Access

The Toolkit has multiple CIDR block settings to allow configuring network access to the environment for both external and internal connections. Through these settings you can restrict network access as required.

Where possible the Toolkit aims to configure network access minimally but due to the range of supported environments it's not able to do so in every case. As such it's always recommended to review the below in full and adjust as necessary.

Refer to the below sections for more detail.

### External (Terraform)

To lock down external network access to particular CIDR blocks these _optional_ settings can be used in Terraform:

- `default_allowed_ingress_cidr_blocks`- A list of CIDR blocks that configures the IP ranges that will be able to access the network externally. This will apply to all external firewall rules that the Toolkit configures. Default is `["0.0.0.0/0"]`. More granular control over rules are also available via these settings:
  - `http_allowed_ingress_cidr_blocks`- A list of CIDR blocks that configures the IP ranges that will be able to access GitLab over HTTP/HTTPs.
  - `ssh_allowed_ingress_cidr_blocks`- A list of CIDR blocks that configures the IP ranges that will be able to access GitLab over SSH.
  - `external_ssh_allowed_ingress_cidr_blocks`- A list of CIDR blocks that configures the IP ranges that will be able to access the network over SSH.
  - `icmp_allowed_ingress_cidr_blocks`- **GCP and Azure only** - A list of CIDR blocks that configures the IP ranges that will be able to access the network over ICMP.

### Internal (Ansible)

To lock down internal network access to particular CIDR blocks these _optional_ settings can be used in Ansible:

- `postgres_md5_auth_cidr_blocks` - A list of CIDR blocks to be allowed access to [Postgres (Omnibus)](https://docs.gitlab.com/omnibus/settings/database.html#configure-postgresql-block) with authentication. Default is `['0.0.0.0/0']`.
  >>> [!note]
  There are [additional considerations for this setting when using Geo](https://docs.gitlab.com/ee/administration/geo/setup/database.html#postgresql-replication).

  Some known issues exist with this setting in certain setups - [gitlab-org/omnibus-gitlab#6594](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6594) and [gitlab-org/omnibus-gitlab#6590](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6590).
  >>>
- `geo_tracking_postgres_md5_auth_cidr_blocks` - A list of CIDR blocks to be allowed access to [Geo Tracking Postgres (Omnibus)](https://docs.gitlab.com/ee/administration/geo/replication/multiple_servers.html#step-3-configure-the-geo-tracking-database-on-the-geo-secondary-site). Default is `['0.0.0.0/0']`.
- `gitlab_rails_monitoring_cidr_blocks` - A list of CIDR blocks to be allowed access to [GitLab's Health Check endpoints](https://docs.gitlab.com/ee/administration/monitoring/health_check.html). Required for Load Balancers to perform Health Checks. Note, when changing this setting it should include any Load Balancers performing health checks, including any Toolkit provided HAProxy Load Balancers. Default is `['0.0.0.0/0']`.

## Configuring Internal Connection Type (IPs and Hostnames)

The Toolkit by default uses IPs for internal connections. However, this can be switched to use internal hostnames as discovered by Ansible via the following setting in your [`vars.yml`](environment_configure.md#environment-config-varsyml) file:

- `internal_addr_use_hostnames` - Flag to switch the Toolkit to use internal hostnames for connections. Default is `false`.

>>> [!note]
Internal hostnames are available by default on major cloud providers - [GCP](https://cloud.google.com/compute/docs/internal-dns), [AWS](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-naming.html), [Azure](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-name-resolution-for-vms-and-role-instances#reverse-dns-considerations)

Terraform output displays these hostnames for each VM. For On Prem installations, hostnames and DNS must be configured separately.
>>>

## Health Checks

The Toolkit will perform some health checks as part of it's set up to ensure it can in turn run actions that require a running environment. It does this by polling the [Readiness endpoint](https://docs.gitlab.com/ee/administration/monitoring/health_check.html#readiness) of the environment.

The URLs it polls to perform these health checks can be changed as required in scenarios such as when the Toolkit may not be able to reach the environment URL directly. However it's generally only recommended to change these settings if strictly required as if the changed URL does not return a valid health check of the instance it will lead to build failures and instability.

The Health Check settings that are available in Ansible and can be changed via the [`vars.yml`](environment_configure.md#environment-config-varsyml) file are as follows:

- `health_check_url` - The main Health Check URL for the GitLab instance. Defaults to `<external_url>/-/readiness`.
- `geo_primary_health_check_url` - (Geo only) The main Health Check URL for the primary GitLab instance. Defaults to `<geo_primary_external_url>/-/readiness`.
- `geo_primary_health_check_url` - (Geo only) The main Health Check URL for the secondary GitLab instance. Defaults to `<geo_secondary_external_url>/-/readiness`.
- `gitlab_rails_local_health_check_url` - (Zero Downtime Upgrade only) The Health Check URL for the local Rails instance on each node. It's not recommended to change this setting unless absolutely necessary. Defaults to `http[s]://localhost/-/readiness`. 

## Offline Setup Guidance

The Toolkit supports setting up an [offline environment without internet access](https://docs.gitlab.com/ee/topics/offline/quick_start_guide.html). However, this does require some additional manual setup to function properly as there are several areas that the Toolkit expects internet access by default and alternatives need to be put in place accordingly.

In this section we'll detail each of these areas below.

> [!tip]
> If the target hosts are running behind a proxy, Ansible can be configured to use this via [remote environment variables](environment_configure.md#ansible-remote-environment-variables).

### Ansible Offline Setup

In an offline environment Ansible will need to be run in the same network as the environment itself. As such, the Dynamic Inventory will need to be switched to return internal IPs instead. This can be done for [GCP](environment_configure.md#google-cloud-platform-gcp) / [AWS](environment_configure.md#amazon-web-services-aws) by changing the `compose.ansible_host` setting  to `private_ip_address`. Azure does not need any additional changes.

Additionally, the Toolkit needs to be configured to run in offline mode to stop it from running any actions that require internet access. This is done in Ansible via the following setting in your [`vars.yml`](environment_configure.md#environment-config-varsyml) file:

- `offline_setup` - Configures the Toolkit to avoid any actions that require the internet. Should only be set when there's no Internet access on the target environment. Default is `false`.

### System Packages

The Toolkit installs several system packages, required for GitLab or itself, on each target OS via the official repos as follows:

- Ubuntu / Debian _Main_ - `aptitude curl openssh-server ca-certificates tzdata python3-pip nfs-common postfix jq libpq-dev`
- RHEL _Main, EPEL_ - `curl openssh-server ca-certificates tzdata python3-pip python3-devel nfs-utils postfix jq gcc yum-plugin-versionlock libpq-devel`
- Amazon Linux 2023 _Main_ - `openssh-server ca-certificates tzdata python3-pip python3-devel nfs-utils postfix jq gcc yum-plugin-versionlock libpq-devel`

> [!tip]
> For the most up-to-date list of packages it's recommend to check the `system_packages_*` variables [in this file](../ansible/roles/common/defaults/main.yml).

Additionally the following packages may be installed depending on the functionality enabled:

- `nvme-cli` - [Data Disks](environment_advanced.md#data-disks-gcp-aws) (AWS)
- `socat` - [Let's Encrypt SSL setup on HAProxy External nodes](environment_advanced_ssl.md#lets-encrypt-generated-certificates).
- `unattended-upgrades` (Ubuntu / Debian) / `dnf-automatic` (RHEL 9, Amazon Linux 2023) - [Automatic Security Upgrades](environment_advanced.md#automatic-security-upgrades)
- `nfs-kernel-server` (Ubuntu / Debian) / `nfs-utils` (RHEL 9, Amazon Linux 2023) - [NFS Server setup for Object Data](environment_advanced.md#nfs-for-object-data)
- `cron` (Debian 12) - [Let's Encrypt SSL for HAProxy External](environment_advanced_ssl.md#lets-encrypt-generated-certificates)

When `offline_setup` is configured the Toolkit will not attempt to set up any repos or install the required packages. As such, you are required to ensure the packages are present before running Ansible. Note this also disables any setup of [Automatic Security Upgrades](environment_advanced.md#automatic-security-upgrades).

There are various ways this can be tackled. While this is outside the scope of this guide, all that's required here is that the packages are present beforehand. Some examples include installing the packages via an offline repo, directly via `deb` / `rpm` files.

### Python Packages

The Toolkit also installs several Python packages via PyPI onto the system to be used by Ansible as required - `pexpect<=4.9.0, psycopg2<=3.2.1`.

When `offline_setup` is configured the Toolkit will not attempt to set up these packages. As such, you are required to ensure the packages are present before running Ansible. Similar to [System Packages](#system-packages) this can be done in [several ways](https://pip.pypa.io/en/stable/cli/pip_install/#pip-install-examples) such as installing the packages via an offline PyPI repo or directly.

> [!tip]
> For the most up-to-date list of Python packages it's recommend to check the `python_packages` variable [in this file](../ansible/roles/common/defaults/main.yml).

### Ansible Galaxy Roles

The Toolkit also depends on several [Ansible Galaxy](https://galaxy.ansible.com/ui/) roles to install some dependencies depending on the setup.

When `offline_setup` is configured, the Toolkit will not attempt to run these roles unless specific variables have been provided to configure those roles to work in a local setup accordingly. Read below for more details on each:

- [`geerlingguy.node_exporter`](https://github.com/geerlingguy/ansible-role-node_exporter) - Installs Node Exporter on HAProxy, OpenSearch and NFS nodes.
  - If `node_exporter_download_url` has been configured to a URL, the Toolkit will assume this is available locally and run the role.
- [`geerlingguy.docker`](https://github.com/geerlingguy/ansible-role-docker) - Installs Docker on HAProxy and OpenSearch nodes.
  - If `docker_add_repo` has been configured to `false` the Toolkit will assume a local repo is already present on the node and run the role.
  - If `docker_repo_url` has been configured to a URL, the Toolkit will assume this is available locally and run the role.
  - Before running the Toolkit download the specific versions of [HAProxy](https://hub.docker.com/_/haproxy/) and [OpenSearch](https://hub.docker.com/r/opensearchproject/opensearch) docker images on the relevant nodes. To determine the exact tag needed for your installation, check the Toolkit default variables: [`haproxy_docker_image`](../ansible/roles/haproxy/defaults/main.yml) and [`opensearch_docker_image`](../ansible/roles/opensearch/defaults/main.yml).

### GitLab Omnibus Package

[By default](environment_configure.md#gitlab-omnibus-installation-options), the Toolkit will deploy the latest [GitLab EE Omnibus package](https://packages.gitlab.com/gitlab/gitlab-ee) via [the official repo](environment_configure.md#repository).

When `offline_setup` is configured the Toolkit will not attempt to do this. As such, you should configure the Toolkit to [install GitLab directly via a file](environment_configure.md#direct).

### GitLab Helm Charts

By default, the Toolkit will deploy the latest [GitLab Chart](https://gitlab.com/gitlab-org/charts/gitlab) via [the official repo](https://charts.gitlab.io/).

When `offline_setup` is enabled, the Toolkit won't automatically fetch the GitLab Charts repository from a Helm Charts server. As such, you should first prepare your Ansible control node to have the repository available locally to Helm or install the GitLab Charts package directly. Once prepared, configure the Toolkit by setting the following setting depending on the approach:

- `gitlab_charts_ref`: The [ref](https://docs.ansible.com/ansible/latest/collections/kubernetes/core/helm_module.html#parameter-chart_ref) for a GitLab Charts repository locally available to Helm or the direct path / URL to a GitLab Charts package file in the `.tgz` format.

### Version Check and Service Ping

While the Toolkit is not setting this up directly, GitLab defaults to enabling a callback Version Check and Service Ping. [Refer to the docs](https://docs.gitlab.com/ee/topics/offline/quick_start_guide.html#disable-version-check-and-service-ping) on how to disable this.
