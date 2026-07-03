# Geo

- [GitLab Environment Toolkit - Quick Start Guide](../environment_quick_start_guide.md)
- [GitLab Environment Toolkit - Preparing the environment](../environment_prep.md)
- [GitLab Environment Toolkit - Provisioning the environment with Terraform](../environment_provision.md)
- [GitLab Environment Toolkit - Configuring the environment with Ansible](../environment_configure.md)
- [GitLab Environment Toolkit - Advanced - Custom Config / Tasks / Files, Data Disks, Advanced Search, Container Registry and more](../environment_advanced.md)
- [GitLab Environment Toolkit - Advanced - SSL](../environment_advanced_ssl.md)
- [GitLab Environment Toolkit - Advanced - Network Setup](../environment_advanced_network.md)
- [GitLab Environment Toolkit - Advanced - Monitoring](../environment_advanced_monitoring.md)
- [GitLab Environment Toolkit - Upgrades (Toolkit, Environment)](../environment_upgrades.md)
- [GitLab Environment Toolkit - Considerations After Deployment - Backups, Security](../environment_post_considerations.md)
- [GitLab Environment Toolkit - Geo](README.md)
  - [**GitLab Environment Toolkit - Geo - Provisioning the environment with Terraform**](geo_provision.md)
  - [GitLab Environment Toolkit - Geo - Configuring the environment with Ansible](geo_configure.md)
  - [GitLab Environment Toolkit - Geo - Advanced](geo_advanced.md)
- [GitLab Environment Toolkit - Troubleshooting](../environment_troubleshooting.md)

[TOC]

## Terraform

The main steps, up to the provisioning step, for [GitLab Environment Toolkit - Building environments](../environment_provision.md) should be followed when creating a new Terraform project. The following modifications to the standard Terraform provisioning apply.

### Directory structure

When creating a new Terraform site for Geo it is recommended to create a new subfolder for your Geo deployment with sub-folders below that for each Geo sites config. Although not required, this does help to keep all the config for a single Geo deployment in one location. Each separate environment will always need their own folder here for Terraform to manage their State correctly.

```bash
my-geo-deployment
    ├── site1
    ├── site2
    └── site3
    ...
```

In each site directory the site's specific `environment.tf`, `main.tf` and `variables.tf` files are stored.

### Site environment sizes

The size of each Geo site environment does not do not need to be the same. It's not uncommon to have the secondary sites be a smaller size for example.

The Geo process will work for any combination with the same steps. You can find examples of various environment sizes following the reference architectures under [/examples](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/tree/main/examples).
 
Once you have selected the desired sizes we will need to modify them to allow for Geo. The first step is to adjust the `ref_arch` module source variable, within the `environment.tf` file, to point to the right location. If you've followed the folder structure above, you will need to add an additional `../` to the path as we are now using sub-folders. For example:

```tf
module "gitlab_ref_arch_*" {
  source = "../../modules/gitlab_ref_arch_*"

  [...]
```

### Geo variables configuration

Next you need to add some new labels to every site within you deployment. These labels are used to identify each site as belonging to your Geo deployment:

- `geo_site` - used to identify each site with unique identifier. This should be a unique way to identify a site e.g. `london-office`. We recommend avoiding terms like primary and secondary in these site names, this is because the primary and secondary sites can change when performing failover.
- `geo_deployment` - used to identify that primary and secondary sites belong to the same Geo deployment. This must be unique across all Geo deployments that will be stored alongside each other.

> [!note]
> `gitlab_ref_arch_nutanix` already exposes both `geo_site` and `geo_deployment` variables, following the same pattern as the other `ref_arch` modules.

You will need to add them into your `environment.tf` file:

```tf
module "gitlab_ref_arch_nutanix" {
  source = "../../modules/gitlab_ref_arch_nutanix"

  geo_site = "geo-site-london"
  geo_deployment = "my-geo-deployment"

  [...]
```

Once all settings are in place we can run the `terraform apply` command against the primary site followed by any secondary sites.

## Object Storage Replication

By default, object storage replication will be handled by GitLab. This fork does not provision managed Object Storage or offer a provider-managed replication option (Nutanix has no equivalent module support for this) - Object Storage for each site must be configured separately via [Custom Config](../environment_advanced.md#custom-config), and cross-site replication of the underlying buckets (e.g. via Nutanix Objects replication policies, or your S3-compatible store's own replication feature) should be set up directly against that storage layer rather than through Terraform.

## Network Connectivity Between Sites

Geo sites need bidirectional network connectivity for PostgreSQL streaming replication and the [internal URLs](https://docs.gitlab.com/ee/administration/geo/#internal-url) used between them. This fork's Nutanix module does not manage network peering/VPN infrastructure between sites (Nutanix AHV has no Terraform-managed equivalent of cloud provider VPC peering in this fork) - if your Geo sites live on separate subnets/VLANs or Nutanix clusters, connectivity between them (VPN, routing, firewall rules) needs to be established at the network level before provisioning.
