# Advanced - Network Setup

- [GitLab Environment Toolkit - Quick Start Guide](environment_quick_start_guide.md)
- [GitLab Environment Toolkit - Preparing the environment](environment_prep.md)
- [GitLab Environment Toolkit - Provisioning the environment with Terraform](environment_provision.md)
- [GitLab Environment Toolkit - Configuring the environment with Ansible](environment_configure.md)
- [GitLab Environment Toolkit - Advanced - Custom Config / Tasks / Files, Data Disks, Advanced Search, Container Registry and more](environment_advanced.md)
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

By default, on Nutanix the Toolkit attaches VMs to a pre-existing subnet/VLAN (passed in as `subnet_uuid`) rather than creating or managing network infrastructure itself - see the [Nutanix section of Provisioning the environment with Terraform](environment_provision.md#nutanix) for details. There are no Terraform-managed network security policies (equivalent to cloud provider security groups/NSGs/VPC peering) in this fork; network access control should be handled at the Nutanix/AHV or upstream network level.

On this page we'll detail the other supported advanced network-related setups you can do with the Toolkit. We recommend you only do these setups if you have a good working knowledge of both the Toolkit and what the specific setups involve.

[TOC]

## Configuring Network CIDR Access

The Toolkit has multiple CIDR block settings to allow configuring network access to the environment for both external and internal connections. Through these settings you can restrict network access as required.

Where possible the Toolkit aims to configure network access minimally but due to the range of supported environments it's not able to do so in every case. As such it's always recommended to review the below in full and adjust as necessary.

Refer to the below sections for more detail.

### External (Terraform)

To lock down external network access to particular CIDR blocks these _optional_ settings can be used in Terraform:

> [!note]
> The `gitlab_ref_arch_nutanix` module does not currently manage network security policies/firewall rules (Nutanix AHV has no direct Terraform-managed equivalent of cloud provider security groups in this fork). Restricting external and internal network access by CIDR block should be handled at the network/VLAN or upstream firewall level instead.

### Internal (Ansible)

To lock down internal network access to particular CIDR blocks these _optional_ settings can be used in Ansible:

- `postgres_md5_auth_cidr_blocks` - A list of CIDR blocks to be allowed access to [Postgres (Omnibus)](https://docs.gitlab.com/omnibus/settings/database.html#configure-postgresql-block) with authentication. Default is `['0.0.0.0/0']`.
  >>> [!note]
  There are [additional considerations for this setting when using Geo](https://docs.gitlab.com/ee/administration/geo/setup/database.html#postgresql-replication).

  Some known issues exist with this setting in certain setups - [gitlab-org/omnibus-gitlab#6594](https://gitlab.com/gitlab-org/omnibus-gitlab/-/work_items/6594) and [gitlab-org/omnibus-gitlab#6590](https://gitlab.com/gitlab-org/omnibus-gitlab/-/work_items/6590).
  >>>
- `geo_tracking_postgres_md5_auth_cidr_blocks` - A list of CIDR blocks to be allowed access to [Geo Tracking Postgres (Omnibus)](https://docs.gitlab.com/ee/administration/geo/replication/multiple_servers.html#step-3-configure-the-geo-tracking-database-on-the-geo-secondary-site). Default is `['0.0.0.0/0']`.
- `gitlab_rails_monitoring_cidr_blocks` - A list of CIDR blocks to be allowed access to [GitLab's Health Check endpoints](https://docs.gitlab.com/ee/administration/monitoring/health_check.html). Required for Load Balancers to perform Health Checks. Note, when changing this setting it should include any Load Balancers performing health checks, including any Toolkit provided HAProxy Load Balancers. Default is `['0.0.0.0/0']`.

## Configuring Internal Connection Type (IPs and Hostnames)

The Toolkit by default uses IPs for internal connections. However, this can be switched to use internal hostnames as discovered by Ansible via the following setting in your [`vars.yml`](environment_configure.md#environment-config-varsyml) file:

- `internal_addr_use_hostnames` - Flag to switch the Toolkit to use internal hostnames for connections. Default is `false`.

>>> [!note]
Nutanix AHV does not provide managed internal DNS for VM hostnames. Terraform output displays the hostnames the Toolkit assigns to each VM, but resolving them to internal IPs requires DNS or hosts-file entries to be configured separately on your network. For On Prem installations, hostnames and DNS must likewise be configured separately.
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

In an offline environment Ansible will need to be run in the same network as the environment itself, with access to nodes over their internal IPs/hostnames.

Additionally, the Toolkit needs to be configured to run in offline mode to stop it from running any actions that require internet access. This is done in Ansible via the following setting in your [`vars.yml`](environment_configure.md#environment-config-varsyml) file:

- `offline_setup` - Configures the Toolkit to avoid any actions that require the internet. Should only be set when there's no Internet access on the target environment. Default is `false`.

### System Packages

The Toolkit installs several system packages, required for GitLab or itself, on each target OS via the official repos as follows:

- Ubuntu / Debian _Main_ - `aptitude curl ca-certificates tzdata`
- RHEL _Main_ - `curl ca-certificates tzdata yum-plugin-versionlock`
- Amazon Linux 2023 _Main_ - `ca-certificates tzdata yum-plugin-versionlock`

> [!tip]
> For the most up-to-date list of packages it's recommend to check the `system_packages_*` variables [in this file](../ansible/roles/common/defaults/main.yml).

Additionally the following packages may be installed depending on the functionality enabled:

- `openssh-server` - GitLab Rails nodes when `gitlab_shell_ssh_daemon` is `openssh` (default)
- `python3-psycopg2 python3-pexpect` (Ubuntu / Debian) / `python3-psycopg2 python3-pexpect python3-requests` (RHEL, Amazon Linux 2023) - nodes with external database or Geo configurations
- `socat` - [Let's Encrypt SSL setup on HAProxy External nodes](environment_advanced_ssl.md#lets-encrypt-generated-certificates)
- `unattended-upgrades` (Ubuntu / Debian) / `dnf-automatic` (RHEL 9/10, Amazon Linux 2023) - [Automatic Security Upgrades](environment_advanced.md#automatic-security-upgrades)
- `nfs-kernel-server` (Ubuntu / Debian) / `nfs-utils` (RHEL, Amazon Linux) - [NFS Server setup for Object Data](environment_advanced.md#nfs-for-object-data)
- `cron` (Debian 12) / `cronie` (Amazon Linux 2023) - [Let's Encrypt SSL for HAProxy External](environment_advanced_ssl.md#lets-encrypt-generated-certificates)

When `offline_setup` is configured the Toolkit will not attempt to set up any repos or install the required packages. As such, you are required to ensure the packages are present before running Ansible. Note this also disables any setup of [Automatic Security Upgrades](environment_advanced.md#automatic-security-upgrades).

There are various ways this can be tackled. While this is outside the scope of this guide, all that's required here is that the packages are present beforehand. Some examples include installing the packages via an offline repo, directly via `deb` / `rpm` files.

### Python Packages

The Toolkit installs `python3-psycopg2`, `python3-pexpect`, and (on RHEL) `python3-requests` as system packages on nodes that require them (external database and Geo configurations). These are installed from the standard OS repos and are covered by the distro's support and security backporting policy.

On Amazon Linux 2 only, `psycopg2` and `pexpect` are installed via pip as the equivalent system packages are not available.

> [!tip]
> For the most up-to-date list of Python packages check the `system_python_packages_*` variables [in this file](../ansible/roles/common/defaults/main.yml).

#### Customising the Python version for packages

On RHEL, the Python packages default to the unversioned `python3-*` names which resolve to the system Python. Environments that manage a non-default Python version alongside the system Python and have configured `ansible_python_interpreter` accordingly can override the `system_python_packages_rhel` variable in `vars.yml` to use the corresponding versioned packages:

```yaml
ansible_python_interpreter: /usr/bin/python3.12
system_python_packages_rhel: ['python3.12-psycopg2', 'python3.12-pexpect', 'python3.12-requests']
```

This ensures the Toolkit's Ansible module dependencies are installed into the correct Python environment. Note that package availability varies by RHEL version and the packages must be available in a configured repo.

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

### Version Check and Service Ping

While the Toolkit is not setting this up directly, GitLab defaults to enabling a callback Version Check and Service Ping. [Refer to the docs](https://docs.gitlab.com/ee/topics/offline/quick_start_guide.html#disable-version-check-and-service-ping) on how to disable this.
