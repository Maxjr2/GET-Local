# Advanced - Geo

- [GitLab Environment Toolkit - Quick Start Guide](environment_quick_start_guide.md)
- [GitLab Environment Toolkit - Preparing the environment](environment_prep.md)
- [GitLab Environment Toolkit - Provisioning the environment with Terraform](environment_provision.md)
- [GitLab Environment Toolkit - Configuring the environment with Ansible](environment_configure.md)
- [GitLab Environment Toolkit - Advanced - Custom Config / Tasks / Files, Data Disks, Advanced Search, Container Registry and more](environment_advanced.md)
- [GitLab Environment Toolkit - Advanced - Cloud Native Hybrid](environment_advanced_hybrid.md)
- [GitLab Environment Toolkit - Advanced - Component Cloud Services / Custom (Load Balancers, PostgreSQL, Redis)](environment_advanced_services.md)
- [GitLab Environment Toolkit - Advanced - SSL](environment_advanced_ssl.md)
- [GitLab Environment Toolkit - Advanced - Network Setup](environment_advanced_network.md)
- [**GitLab Environment Toolkit - Advanced - Geo**](environment_advanced_geo.md)
- [GitLab Environment Toolkit - Advanced - Monitoring](environment_advanced_monitoring.md)
- [GitLab Environment Toolkit - Upgrades (Toolkit, Environment)](environment_upgrades.md)
- [GitLab Environment Toolkit - Considerations After Deployment - Backups, Security](environment_post_considerations.md)
- [GitLab Environment Toolkit - Troubleshooting](environment_troubleshooting.md)

The Toolkit supports the provisioning and configuration of [GitLab Geo](https://about.gitlab.com/solutions/geo/), where multiple secondary environments can be set up as replicas of the primary for more distributed setups.

On this page we'll detail how to setup Geo. We recommend you only do follow this setup if you have a good working knowledge of both the Toolkit and Geo.

[[_TOC_]]

## Creating a Geo Deployment

When provisioning a Geo deployment there are a few differences to a single environment that need to be made throughout the process to allow the Toolkit to properly manage the deployment:

- Both environments should share the same admin credentials. For example in the case of GCP the same Service Account.
- The GitLab license is shared between all sites. This means the license only needs to be applied to the primary site.

As shown above, for the most part, the process is the same as when creating a single environment and as such the standard Toolkit steps defined in the earlier docs must be followed before creating a Geo deployment.

The process to build the environments follows the documentation for [Geo for multiple nodes](https://docs.gitlab.com/ee/administration/geo/replication/multiple_servers.html). The high level steps that will be followed are:

1. Provision at least 2 environments with Terraform
    - Each environment will share some common labels to identify them as being part of the same Geo deployment
    - Each environment will be identified with a unique site name
1. Configure the environments with Ansible
    - Each environment will work as a separate environment until Geo is configured
1. Configure Geo on the Primary and Secondary sites
    - One environment will be identified as being a Primary site and all others will be a Secondary

### Terraform

When creating a new Terraform site for Geo it is recommended to create a new subfolder for your Geo deployment with 2 sub-folders below that for each Geo sites config. Although not required this does help to keep all the config for a single Geo deployment in one location. Each separate environment however will always still need their own folders here for Terraform to manage their State correctly.

```bash
my-geo-deployment
    ├── site1
    ├── site2
    └── site3
    ...
```

After this it is recommended to copy an existing reference architecture for each sites folders. You could copy the 25k reference architecture to use as your primary site and the 3k for your secondary, or use 5k for both your primary and secondary sites, the Geo process will work for any combination with the same steps. It is recommended to use the same sized environment for each site, this is for disaster recovery reasons where a 25k primary going down could then send 25k users to a secondary instance only sized for 3k users.

The main steps for [GitLab Environment Toolkit - Building environments](environment_provision.md) should be followed when creating a new Terraform project.

Once you have copied the desired architecture sizes we will need to modify them to allow for Geo. The first step is to adjust the `ref_arch` module source variable to point to the right location if you've followed the folder structure above. You will need to add an additional `../` to the path as we are now using sub-folders. For example:

```tf
module "gitlab_ref_arch_*" {
  source = "../../modules/gitlab_ref_arch_*"

  [...]
```

Next you need to add 2 new labels that helps to identify the machines as belonging to our Geo deployment and to give them a unique site name:

- `geo_site` - used to identify a machine with unique identifier. This should be a unique way to identify a site e.g. `london-office`. We recommend avoiding terms like primary and secondary in these site names, this is because the primary and secondary sites can change when performing failover.
- `geo_deployment` - used to identify that primary and secondary sites belong to the same Geo deployment. This must be unique across all Geo deployments that will be stored alongside each other.

The recommended way to do this is to first set them in the `variables.tf` file, for example:

:information_source:&nbsp; The configurations below are needed on all geo sites.

```tf
variable "geo_site" {
    default = "geo-site-london"
}

variable "geo_deployment" {
    default = "my-geo-deployment"
}
```

Next you should add them into the selected cloud providers module's call under `environment.tf`:

```tf
module "gitlab_ref_arch_*" {
  source = "../../modules/gitlab_ref_arch_*"

  geo_site = var.geo_site
  geo_deployment = var.geo_deployment

  [...]
```

Once each site is configured we can run the `terraform apply` command against each project. You can run this command against all sites at the same time.

#### VPC Peering (AWS)

:information_source:&nbsp; Currently Peering is only available when using a single secondary site.

Enabling [AWS VPC Peering](https://docs.aws.amazon.com/vpc/latest/peering/vpc-peering-basics.html) will allow traffic to flow in both directions from a primary and secondary site just like normal internal connections. This is required if the sites are located in different regions.

AWS VPC peering requires a handshake, I.E. A VPC must first request the Peering and the other has to then accept it. As such, this requires Terraform to be run a couple of times to go through this process. To do this, first provision the primary site with `terraform apply`, this will output some values that are required by the secondary site to setup peering.

```json
  "network" = {
    "peer_connection_id" = "<peer_connection_id>"
    "vpc_cidr_block" = "<vpc_cidr_block>"
    "vpc_id" = "<vpc_id>"
    "vpc_subnet_priv_ids" =["vpc_subnet_priv_id1", "vpc_subnet_priv_id2"]
    "vpc_subnet_pub_ids" = ["vpc_subnet_pub_id1", "vpc_subnet_pub_id2"]
  }
```

Using this output, add the below values to the secondaries `environment.tf` file. These values are used so that each secondary is able to setup a peering connection with the primary's VPC.

- `peer_region` - The AWS region used for the primary site. This won't be in the output for Terraform but is something that is defined as part of the environment config.
- `peer_vpc_id` - The VPC ID of the primary site.
- `peer_vpc_cidr` - The CIDR used for the internal network as part of the VPC.

:information_source:&nbsp; When setting up VPC peering, the CIDR used for each VPC must be different and cannot overlap.

Now run `terraform apply` for the secondary sites, once this completes the VPC connection details will be output in `network`, similar to the primary, this time take the `peering_id` and `vpc_cidr_block` and add them into the primary sites `environment.tf`:

- `peer_connection_id` - The ID of the peer connection created as part of the secondaries `terraform apply`
- `peer_vpc_cidr` - The CIDR used for the internal network as part of the VPC on the secondary site.

Once added you will need to rerun `terraform apply` for the primary site. This will accept the peering request created by the secondaries as well as create routing and firewall rules to allow traffic from the secondary VPC. After this, peering will now be configured and allow your sites to communicate internally.

#### Object Storage Replication (AWS)

Enabling [AWS Object Storage Replication](https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication.html) will automatically copy new items from your current primary's S3 storage buckets to your secondaries. To enable this you will first need to run `terraform apply` for both your primary and secondary sites. Once the secondary site is complete you will be able to take the object storage buckets ARNs from the Terraform output.

```json
  "object_storage_buckets": {
    "artifacts" = "<artifacts_bucket_arn>"
    "backups" = "<backups_bucket_arn>"
    "dependency-proxy" = "<dependency-proxy_bucket_arn>"
    "lfs" = "<lfs_bucket_arn>"
    "mr-diffs" = "<mr-diffs_bucket_arn>"
    "packages" = "<packages_bucket_arn>"
    "registry" = "<registry_bucket_arn>"
    "terraform-state" = "<terraform-state_bucket_arn>"
    "uploads" = "<uploads_bucket_arn>"
    "ci_secure_files" = "<ci_secure_files_bucket_arn>"
  },
  "object_storage_kms_key_arn": "<object_storage_kms_key_arn>"
```

Using this output, add the below values to the primaries `environment.tf` file. These values are used so that the primary can setup replication rules with the secondaries buckets.

- `object_storage_destination_buckets` - A map of each destination buckets name and ARN. For example:

:exclamation:&nbsp; You must ensure you have copied over all the settings listed above in full. Failure to do so will cause Geo Replication to fail.

```yml
object_storage_destination_buckets = tomap({
    "artifacts"        = "<artifacts_bucket_arn>"
    "backups"          = "<backups_bucket_arn>"
    "dependency-proxy" = "<dependency-proxy_bucket_arn>"
    "lfs"              = "<lfs_bucket_arn>"
    "mr-diffs"         = "<mr-diffs_bucket_arn>"
    "packages"         = "<packages_bucket_arn>"
    "registry"         = "<registry_bucket_arn>"
    "terraform-state"  = "<terraform-state_bucket_arn>"
    "uploads"          = "<uploads_bucket_arn>"
    "ci_secure_files"  = "<ci_secure_files_bucket_arn>"
  })
```

- `object_storage_replica_kms_key_id` - The ARN used to encrypt the secondaries object storage buckets.

Once the settings have been added you will need to rerun `terraform apply` for the primary site. This will create the replication rules from the primaries source buckets to the secondaries. Finally, be sure to add `geo_enable_object_storage_replication: false` into your primary sites ansible inventory. This will prevent Ansible from enabling Geo managed object storage replication.

:information_source:&nbsp; Once replication is enabled AWS will only replicate new objects. AWS recommends using [batch replication](https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-batch-replication-batch.html) to copy any existing items.

### Ansible

We will need to start by creating new inventories for a Geo deployment. For Geo we will require at least 2 inventories, 1 for each site. It is recommended to store these in one parent folder to keep all the config together.

```bash
ansible
└── environments
    └── my-geo-deployment
        ├── site1
        |   ├── files
        |   └── inventory
        └── site2
            ├── files
            └── inventory
```

For Omnibus environments the site folders are treated the same as non Geo environments with the exception of needing 1 new variable:

- `geo_primary_site_group_name`/`geo_secondary_site_group_name` - These should match the `geo_site` that was set in terraform for the site you want to use as a primary/secondary, any `-` should be replaced with `_` as the names are altered when pulled from the cloud provider. Each setting only needs to go into the site that corresponds to its role i.e. primary or secondary.

You can also remove the GitLab license from the sites that will not be set as the primary before running the `ansible-playbook` command. To remove the license from the secondary site you can just remove the `gitlab_license_file` or `gitlab_subscription_activation_code` setting from the secondary `vars.yml` file.

Once the new settings are added the steps for [GitLab Environment Toolkit - Configuring the environment with Ansible](environment_configure.md) should be followed for each site.

For Cloud Native Hybrid environments some variables will need to be added to the primary and secondary site `vars.yml` files.

Primary Sites `vars.yml`:

```yml
cloud_native_hybrid_geo: true
cloud_native_hybrid_geo_role: primary
```

Secondary Site `vars.yml`:

```yml
cloud_native_hybrid_geo: true
cloud_native_hybrid_geo_role: secondary
```

Also for Omnibus and Cloud Native Hybrid environments it's required to add a new `keyed_group` to your Dynamic Inventory config file for your chosen cloud provider:

GCP:

```yaml
- key: labels.gitlab_geo_site
    separator: ''
- key: labels.gitlab_geo_full_role
    separator: ''
```

AWS:

```yaml
- key: tags.gitlab_geo_site
  separator: ''
- key: tags.gitlab_geo_full_role
    separator: ''
```

Azure:

```yaml
- prefix: ''
  separator: ''
  key: tags.gitlab_geo_site | default('ungrouped')
- prefix: ''
  separator: ''
  key: tags.gitlab_geo_full_role | default('ungrouped')
```

Once the inventories for primary and secondaries are complete you can use Ansible to configure GitLab. Once complete you will have multiple independent instances of GitLab. The primary site should have a license installed and the secondaries will not.
As these environments are still separate from each other at this point, they can be built at the same time and are not reliant on each other. Once complete you should be able to log into each environment before continuing.

#### Adding Geo specific config

Before running the `gitlab_geo.yml` playbook you will need to add some more variables to each inventory depending on its initial role as a primary or secondary.

- Primary site settings
  - `geo_primary_external_url` - This should match the `external_url` for the primary site. It is required to set this directly with a value and not to set this to the `external_url` variable. This is due to how [Ansible handles variables when using multiple inventories](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html#using-multiple-inventory-sources).
  - `geo_primary_site_group_name` - This should match the `geo_site` that was set in terraform for the site you want to use as a primary, any `-` should be replaced with `_` as the names are altered when pulled from the cloud provider.
  - `geo_primary_site_name` - This is will be used to identify the sites in the Geo Settings UI. This can be set to any string value.
- Secondary site settings
  - `geo_secondary_external_url` - This should match the `external_url` for the secondary site. It is required to set this directly with a value and not to set this to the `external_url` variable. This is due to how [Ansible handles variables when using multiple inventories](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html#using-multiple-inventory-sources).
  - `geo_secondary_site_group_name` - This should match the `geo_site` that was set in terraform for the sites you want to use as a secondary, any `-` should be replaced with `_` as the names are altered when pulled from the cloud provider.
  - `geo_secondary_site_name` - This is will be used to identify the sites in the Geo Settings UI. This can be set to any string value.

For Cloud Native Hybrid environments you will need to add some more Geo specific variables:

- `cloud_native_hybrid_geo` - This need to be set to `true` in all inventories used for a cloud native hybrid instance.
- `cloud_native_hybrid_geo_role` - Should be set to `primary` or `secondary` depending on the inventory.
- For the below variables, only one version of each variable needs to be set depending on the sites role.
  - `geo_primary_site_prefix`/`geo_secondary_site_prefix` - Set the prefix used for the current site.
  - `geo_primary_site_gcp_project`/`geo_secondary_site_gcp_project` - **GCP only** The name of the GCP project.
  - `geo_primary_site_gcp_zone`/`geo_secondary_site_gcp_zone` - **GCP only** The zone used for this site.
  - `geo_primary_site_aws_region`/`geo_secondary_site_aws_region` - **AWS only** The region used in AWS.

Once done we can then run the command `ansible-playbook -i environments/my-geo-deployment/<secondary>/inventory -i environments/my-geo-deployment/<primary>/inventory playbooks/gitlab_geo.yml`.

:information_source:&nbsp; It should be noted, when passing in multiple inventories the second inventory's variables will take precedence over the first.

Once complete the 2 sites will now be part of the same Geo deployment.

:information_source:&nbsp; When setting up multiple Geo secondaries you will need to rerun the above command replacing the secondary path for each secondary inventory. After the first run the primary will be setup and its tasks can be skipped for each consecutive secondary with the following command `ansible-playbook -i environments/my-geo-deployment/<secondary>/inventory -i environments/my-geo-deployment/<primary>/inventory playbooks/gitlab_geo.yml -t secondary`. Each consecutive site can also be added in parallel by running the command from multiple terminals.

## Geo Proxying for Secondary Sites with a Unified URL

> The Geo Proxying for Secondary Sites is only available for deployments using GitLab versions 14.6 or above.

Before using [Geo Proxying for Secondary Sites](https://docs.gitlab.com/ee/administration/geo/secondary_proxy/index.html) it is recommended to read the current documentation on this feature within GitLab and to understand the scope and limitations of this feature.

To use a single unified URL to access the primary and secondary sites with the Toolkit you will first need to ensure you have 3 unique URLs available.

- Unified URL: This is a geo-based URL that will be used to route traffic to either site based on the users location.
- Primary URL: This is a URL/IP that will always route traffic to the primary site.
- Secondary URL: This is a URL/IP that will always route traffic to the secondary site.

 With the URLs setup you will now need to change a few settings within your inventories to enable this feature.

```yaml
external_url: "<Unified URL>"
geo_primary_external_url: "<Unified URL>"
geo_secondary_external_url: "<Unified URL>"
geo_primary_internal_url: "<Primary URL>"
geo_secondary_internal_url: "<Secondary URL>"
```

Although not required, if you want to disable the Geo proxying feature you can set `geo_disable_secondary_proxying: true` in both your primary and secondary inventories.

### SSL

To use [certificates generated by Let's Encrypt](environment_advanced_ssl.md#lets-encrypt-generated-certificates) with a unified URL, some additional setup is required.

Let's Encrypt should be configured on the Primary site as normal, but for the Secondary site the same certificate is required. As such, you'll need to manually download the generated certificates from your primary site and then set your secondary site's inventory to use them as [user provided certificates](environment_advanced_ssl.md#user-provided-certificates).

For Omnibus installs, if using the Toolkit provided HAProxy load balancers, then the certificates can be found in `/opt/haproxy` on the HAProxy external node. For Cloud Native Hybrid environments, the following commands can be used to get the contents of each file from the primary site, you can then save them locally.

```sh
kubectl get secrets gitlab-gitlab-tls -o jsonpath --template '{.data.tls\.crt}' | base64 --decode
kubectl get secrets gitlab-gitlab-tls -o jsonpath --template '{.data.tls\.key}' | base64 --decode
```

## Failover and Recovery

Before starting the failover or recovery process, the Toolkit will enable [Maintenance Mode](https://docs.gitlab.com/ee/administration/maintenance_mode/index.html). When enabling maintenance mode, a message can be set that will appear in a banner at the top of the site.

- `maintenance_mode_message` - Sets the message to be displayed in a banner at the top of the page. Defaults to "GitLab is undergoing maintenance".

After the failover or recovery process has completed, maintenance mode will be disabled.

### Failover

> The Toolkit automated Geo failover process is available for Geo deployments running GitLab versions 14.2 or above.

The Toolkit provides the ability to failover from a Geo primary site to a secondary site. This process will disable the current primary site and promotes the secondary site to be a standalone GitLab instance.

Before running the failover process you should ensure you have read and completed any required steps outlined in the [Disaster recovery for planned failover](https://docs.gitlab.com/ee/administration/geo/disaster_recovery/planned_failover.html) documentation.

Once you get to the [Promote the secondary site](https://docs.gitlab.com/ee/administration/geo/disaster_recovery/planned_failover.html#promote-the-secondary-site) step in the documentation you can proceed to perform a failover. To do the failover you can use the existing inventories to disable the primary and promote the secondary in a single command `ansible-playbook -i environments/my-geo-deployment/<secondary>/inventory -i environments/my-geo-deployment/<primary>/inventory playbooks/gitlab_geo_failover.yml`. If using multiple secondaries you will need to choose a single secondary that will be promoted to a stand a lone instance until recovery is run.

After failover has occurred it's important to update your inventories to reflect the new roles they now perform and to avoid misconfiguration on subsequent runs. The original primary and secondary inventories need updating. For all environment types you will need to update the settings mentioned in the [Adding Geo specific config](environment_advanced_geo.md#adding-geo-specific-config) section above.

Finally, if using AWS RDS, in the Terraform config for the original secondary site you will need to remove the `rds_postgres_replication_database_arn` variable to prevent any misconfiguration happening on the next Terraform run.

### Recovery

After a failover has been performed it's then possible to take the old Geo primary site and turn it into a secondary. This will attach the old primary to the new primary site and begin the replication process. For a planned failover this could occur as soon as the new primary has been promoted, for an unplanned failover the old primary site should be checked for any issues before performing this step.

Before performing a recovery the inventories must be updated to reflect each site's new roles.

Once done you can perform the recovery process by running the command `ansible-playbook -i environments/my-geo-deployment/secondary/inventory -i environments/my-geo-deployment/<primary>/inventory playbooks/gitlab_geo_recovery.yml`

### AWS RDS

The failover and recovery process when using RDS is largely the same as the non RDS process. However it will also require the use of Terraform.

:information_source:&nbsp; Before running `terraform apply` it is advised to check the output of `terraform plan` and ensure that all changes are expected.

#### Failover

To perform a failover the following terraform settings will need to be updated for the site that will be promoted:

- Set `rds_postgres_replication_database_arn` to `null`.
- Set `rds_postgres_password` to your Postgres password.
- Set `rds_postgres_backup_retention_period` to a value between 0 and 35.

Terraform will complete straight away, however the process can take a few minutes to complete and you will need to wait for AWS to show the database as `Available` before continuing. Once completed, the following additional settings will need to be updated and then the failover process can be followed as normal:

- `postgres_host`
- `geo_secondary_postgres_host`
- `geo_secondary_praefect_postgres_host`
- `geo_tracking_postgres_host`

#### Recovery

The RDS recovery process involves deleting the old primary RDS instance, this is done by removing the `rds_postgres_instance_type` setting from the `environment.tf` file for the site currently being recovered and running `terraform apply`. Once deleted, Add the `rds_postgres_instance_type` setting back into `environment.tf` along with the following settings:

- Set `rds_postgres_replication_database_arn` to the ARN for the new primary site.
- Set `rds_postgres_kms_key_arn` to the KMS key used for the primary site's RDS instance.
- Remove `rds_postgres_password`.
- Remove `rds_postgres_backup_retention_period`.

## Container Registry Replication

To enable Container registry replication you will need to define `container_registry_token` in your `vars.yml` file. For Cloud Native Hybrid environments you will need to specify this setting in both the primary and secondary inventories. For Omnibus environments you can specify it in just the primary inventory.

- `container_registry_token` - Secret value for the container registry authorization header and for the Geo event notification endpoint to use. Value should be a case-sensitive alphanumeric string that starts with a letter.
