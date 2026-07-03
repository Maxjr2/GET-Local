# Advanced - Custom Config / Tasks / Files, Data Disks, Advanced Search and more

- [GitLab Environment Toolkit - Quick Start Guide](environment_quick_start_guide.md)
- [GitLab Environment Toolkit - Preparing the environment](environment_prep.md)
- [GitLab Environment Toolkit - Provisioning the environment with Terraform](environment_provision.md)
- [GitLab Environment Toolkit - Configuring the environment with Ansible](environment_configure.md)
- [**GitLab Environment Toolkit - Advanced - Custom Config / Tasks / Files, Data Disks, Advanced Search, Container Registry and more**](environment_advanced.md)
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

The Toolkit by default will deploy the latest version of the selected [Reference Architecture](https://docs.gitlab.com/ee/administration/reference_architectures/). However, it can also support other advanced setups such as Geo or different component makeups such as Gitaly Sharded.

On this page we'll detail all the supported advanced setups you can do with the Toolkit. We recommend you only do these setups if you have a good working knowledge of both the Toolkit and what the specific setups involve.

[TOC]

## Custom Config

The Toolkit allows for providing custom GitLab config that will be used when setting up components via the Linux package (Omnibus) or Helm charts.

> [!caution]
> **This is an advanced feature, and it must be used with caution**. Any custom config passed will always take precedence and may lead to various unintended consequences or broken environments if not used carefully.

Custom config should only be used in advanced scenarios where you are fully aware of the intended effects or for areas that the Toolkit doesn't support natively due to potential permutations such as:

- [OmniAuth](https://docs.gitlab.com/ee/integration/omniauth.html)
- [Custom Object Storage](https://docs.gitlab.com/ee/administration/object_storage.html)
- [Email](https://docs.gitlab.com/omnibus/settings/smtp.html)
- [GitLab agent server for Kubernetes (KAS)](https://docs.gitlab.com/ee/administration/clusters/kas.html#for-omnibus)
  - The KAS agent will be enabled in the environment as per it's defaults but further configuration of specific keys and URLs are required.

Custom configs are treated the same as our built-in config templates. As such you have access to the same variables for added flexibility.

In this section we detail how to set up custom config for the Linux package (Omnibus) and Helm charts components respectively.

### Linux package (Omnibus)

Providing custom config for components deployed via the Linux package (Omnibus) is done as follows:

1. Create a [gitlab.rb](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template) template file in the correct format with the specific custom settings you wish to apply.
1. By default, the Toolkit looks for [Jinja2 template files](https://docs.ansible.com/ansible/latest/user_guide/playbooks_templating.html) in the [environment's](environment_configure.md#2-set-up-the-environments-inventory-and-config) `files/gitlab_configs` folder path. E.G. `ansible/environments/<env_name>/files/gitlab_configs/<component>.rb.j2`. Save your file in this location with the same name.
    - Files should be saved in Ansible template format - `.j2`.
    - If you wish to store your file in a different location or use a different name the full path that Ansible should use can be set via a variable for each different component e.g. `<component>_custom_config_file`.
    - Available component options: `common`, `consul`, `postgres`, `pgbouncer`, `redis`, `redis_cache`, `redis_persistent`, `praefect_postgres`, `praefect`, `gitaly`, `gitlab_rails`, `sidekiq` and `monitor`.

>>> [!note]
When adding custom configuration for Gitaly or Praefect from GitLab `16.0`, you need to follow the [changed configuration structure](https://docs.gitlab.com/ee/update/#gitaly-omnibus-gitlab-configuration-structure-change) and use the `['configuration']` key, for example:

```rb
gitaly['configuration']['logging']['level'] = 'warn'
```
>>>

With the above done the file will be picked up by the Toolkit and used when configuring the Linux package (Omnibus).

## Custom Tasks

The Toolkit allows for providing custom Ansible tasks that can be run at several points in the setup. This allows you to run tasks as required in addition to the main GitLab setup such as installing monitoring tools.

The Toolkit has hooks to allow tasks to be run at the following points during the setup:

- Common - Tasks to run on every VM **before** the component has deployed such as installing general monitoring tools.
- Linux package (Omnibus) - Tasks to run on specific Linux package (Omnibus) VMs **after** the component has been set up via the Linux package (Omnibus) such as installing any specific tools for the component.
- Post Configure - Tasks to run against the environment **after** setup from the Ansible runner.
- Uninstall - Tasks to run as part of the uninstallation process such as uninstalling any additional tools.

> [!caution]
> **This is an advanced feature, and it must be used with caution**. Running custom tasks may lead to various unintended consequences or broken environments if not used carefully.

Setting up common tasks is done in the same manner for each hook as follows:

1. Create a standard Ansible Tasks yaml file with the tasks you wish to run.
    - The file must be in a format that can be run in Ansible's [`include_tasks`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/include_tasks_module.html) module.
    - You can add the tag `custom_tasks` to your tasks if you wish to run the tasks in isolation.
1. By default, the Toolkit looks for each hook's Custom Tasks file(s) in the [environment inventory's](environment_configure.md#2-set-up-the-environments-inventory-and-config) `files/gitlab_tasks` folder path. E.G. `ansible/environments/<env_name>/files/gitlab_tasks/<custom_tasks_file>.yml`. This is controlled by the following settings for each:
    - `common_custom_tasks_file` - Full path for the Common tasks file. Defaults to `<inventory_dir>/../files/gitlab_tasks/common.yml`.
    - `haproxy_custom_tasks_file` - Full path for the HAProxy tasks file. Defaults to `<inventory_dir>/../files/gitlab_tasks/haproxy.yml`.
    - `<component>_custom_tasks_file` - Full path for Linux package (Omnibus) custom tasks files. Where `<component>` should be replaced with the one intended (options below). Defaults to `<inventory_dir>/../files/gitlab_tasks/<component>.yml`.
      - Available component options: `consul`, `postgres`, `pgbouncer`, `redis`, `redis_cache`, `redis_persistent`, `praefect_postgres`, `praefect`, `gitaly`, `gitlab_rails`, `sidekiq` and `monitor`.
    - `post_configure_custom_tasks_file` - Full path for the Post Configure custom tasks file. Defaults to `<inventory_dir>/../files/gitlab_tasks/post_configure.yml`.
    - `uninstall_custom_tasks_file` - Full path for the uninstallation custom tasks file. Defaults to `<inventory_dir>/../files/gitlab_tasks/uninstall.yml`.

Any task within the [Ansible library](https://docs.ansible.com/projects/ansible/latest/collections/all_plugins.html) can be used for custom tasks, although it's worth noting the following general guidance when writing tasks:

- Any Ansible tasks that aren't core, i.e. available within a standard Ansible install, will need their requirements installed manually before running.
- If there's a requirement to only run Common tasks across all Linux package (Omnibus) VMs only you can do this by setting a `when` condition on the tasks to the Toolkit provided variable `omnibus_node`.
- Except for Common, tasks will run after component setup.

## Custom Files

The Toolkit allows for copying files or folders to component node groups as desired. This can be useful when additional files are required for setup such as SSL certificates.

> [!caution]
> **This is an advanced feature, and it must be used with caution**. Adding custom files may lead to various unintended consequences or broken environments if not used carefully.

Setting up common files is straightforward. All that's required is for you to have the files ready in a location that's reachable by Ansible on the machine it's running on and then configuring Ansible to copy the files or folder from that location to a specified one on the node group as follows:

1. Place the files you wish to be copied for each component node group in a location that's reachable by Ansible. Similar to Custom Tasks we recommend you place your files or folder in the inventory under the `files/` folder, E.G. `ansible/environments/<env_name>/files/<component>/`.
1. Configure Ansible to copy the files and where to via the `*_custom_files_paths` setting (see structure below) in your [`vars.yml`](environment_configure.md#environment-config-varsyml) file.
    - Available component options: `common`, `consul`, `postgres`, `pgbouncer`, `redis`, `redis_cache`, `redis_persistent`, `praefect_postgres`, `praefect`, `gitaly`, `gitlab_rails`, `sidekiq` and `monitor`.

> [!note]
> Files are always copied before any components are configured.

The `*_custom_files_paths` setting is a list of files or folders for each component that Ansible is to copy. An example for Gitaly with descriptions below is as follows:

```yml
gitaly_custom_files_paths: [
  { src_path: "<custom_files_path>/gitaly/example_folder", dest_path: "/etc/gitlab/ssl/", mode: "0644" },
  { src_path: "<custom_files_path>/gitaly/example.file", dest_path: "/etc/gitlab/ssl/" }
]
```

- `*_custom_files_paths` - The main setting for each node group. Default is `[]`.
  - `src_path` - The path on the machine running Ansible where it can expect to find the file or folder to copy.
    - If the path is a folder it will be copied recursively as a child folder.
    - If the path is a folder and ends with a `/` only the contents of the folder will be copied.
  - `dest_path` - The path on the target machine to copy the files to.
    - If the path doesn't exist it will be created when either the path ends with a `/` or `src_path` is a directory.
  - `owner` - Sets the owner of the file or folder when copied. If not specified, the file will be owned by `root`.
  - `group` - Sets the group of the file or folder when copied. If not specified, the file will be owned by the `root` group.
  - `mode` - Sets the permissions for the file or folder to have when copied. If not specified the permissions of the source files or folder are preserved.

With the above done the files will be copied by the Toolkit.

## Custom GitLab Secrets - Linux package (Omnibus)

[GitLab runs with several secrets internally](https://docs.gitlab.com/ee/development/application_secrets.html) that the Toolkit will propagate accordingly across nodes.

As an additional feature, it's possible for you to pass in your own GitLab secrets, either some or all, that the Toolkit will merge with any existing secrets on the environment and subsequently propagate out.

> [!caution]
> **This is an advanced feature, and it must be used with caution**. Adding custom GitLab secrets may lead to various unintended consequences or broken environments if not used carefully.

> [!note]
> This feature is designed for Linux package (Omnibus) setups.

Custom GitLab secrets can be given as a JSON string via the following variable in your [`vars.yml`](environment_configure.md#environment-config-varsyml) file:

- `gitlab_custom_secrets_json` - A JSON string containing any [GitLab secrets](https://docs.gitlab.com/ee/development/application_secrets.html) that is to be used instead of the generated defaults. Any secret passed in this string will always take precedence. Optional, default is `""`.

The value must be correctly formatted JSON that matches the structure of the GitLab secrets file for the Toolkit to parse correctly. An example of one way to do this in Ansible with a multiline YAML string is as follows:

```yml
gitlab_custom_secrets_json: |
  {
    "gitlab_workhorse": {
      "secret_token": "<example_secret>"
    }
  }
```

## Data Disks (Nutanix)

The Toolkit supports provisioning and configuring extra disks, AKA data disks, for each group of machines (i.e. for all Gitaly nodes). With this set up you can have additional disk volumes mounted for storing data for added resilience and flexibility.

Like other resources the process here is similar - The disks are provisioned and attached via Terraform and then configured and mounted via Ansible. Below are sections detailing each step.

> [!note]
> Data Disks configuration only applies to Nutanix Terraform-provisioned environments. For Custom Servers (On Prem) via static inventory, disks must be configured separately - see [Custom Servers (On Prem)](#custom-servers-on-prem).

### Provisioning with Terraform

Using Terraform, provision and attach the disks to the selected machine groups.

Additional config is required in your [`environment.tf`](environment_provision.md#configure-module-settings-environmenttf) file. The config is given per node type and is passed an array of hashes (each hash represents a disk):

```tf
gitaly_data_disks = [
  { name = "data", size = 500, storage_container_uuid = "<storage_container_uuid>", index = 0 },
  { name = "logs", size = 50, storage_container_uuid = "<storage_container_uuid>", index = 1 }
]
```

- `*_data_disks` - The data disk configuration that will be used for every node in the group.
  - `name` - The name for each disk attached. Must be unique per machine. **Required**.
  - `size` - The size of the disk in GB. **Optional**, default is `100`.
  - `storage_container_uuid` - UUID of the Nutanix storage container to create the disk in. **Optional**, defaults to the same storage container used for the boot disk.
  - `index` - The disk index used to identify the device on the VM. Must be unique per machine. **Required**.

### Configuring with Ansible

The next step is to configure and mount the disks.

This is done with Ansible and as such will require additional config in your [`vars.yml`](environment_configure.md#environment-config-varsyml) file.

It's worth noting that the Toolkit will always mount disks via UUID to ensure the correct disks are always mounted in the same way through reboots.

The config for this area is given per node type and is passed an array of dictionaries, where each dictionary represents a disk:

```yaml
gitaly_data_disks:
  - { device_name: 'data', mount_dir: '/var/opt/gitlab' }
  - { device_name: 'logs', mount_dir: '/var/log/gitlab' }
```

- `*_disks` - The main setting for each node group.
  - `device_name` - The block device name of the disk, matching the `name` set for the disk in Terraform's `environment.tf`. **Required**.
  - `mount_dir` - The path on the machine to mount the disk on.

### Suggested disk mount paths for GitLab

This feature can support mounting a disk on any path in machine groups as desired.

For GitLab, we suggest the following mount paths are suggested:

- `/var/opt/gitlab` - Common path for GitLab to store stateful data (e.g. Git Repo data).
- `/var/log/gitlab` - Common path for GitLab to store its logs.

## Gitaly

There are several options for deploying and configuring Gitaly as detailed below.

### Gitaly Deployment Types - Cluster or Sharded

[Gitaly](https://docs.gitlab.com/ee/administration/gitaly/), which is our repo storage backend, can be run in two different ways:

- [Gitaly Cluster](https://docs.gitlab.com/ee/administration/gitaly/praefect.html) - A HA set up that stores the same copy of data on each Gitaly node with additional performance benefits. [Praefect](https://docs.gitlab.com/ee/administration/gitaly/praefect.html#praefect) is additionally deployed in this set up to manage replication and failover.
- [Gitaly Sharded](https://docs.gitlab.com/ee/administration/gitaly/configure_gitaly.html) - Individual Gitaly nodes that don't offer HA.

The Toolkit supports setting up both of these setups. This is controlled simply by not provisioning the Praefect nodes required in Cluster. If these nodes aren't present the Toolkit automatically assumes that the environment is using Gitaly Sharded and will configure in that way.

> [!caution]
> Attempting to switch an existing environment from using Gitaly Cluster to Sharded or vice versa is not supported in the Toolkit and may lead to data loss.

### Gitaly Internal API Callback URL

[Gitaly requires to make an API call to GitLab Shell](https://docs.gitlab.com/ee/administration/gitaly/praefect.html#gitaly), which is deployed alongside Rails, when any Git Push is made to complete the action. This is known as the Internal API Callback.

The Toolkit configures this for you automatically by using the Internal Load Balancer. If using the Toolkit provided HAProxy option this is configured automatically.

In some advanced cases you may need to configure this URL directly, such is when using a custom Internal Load Balancer. This can be done via the following Ansible variable in [Environment `vars.yml` file](environment_configure.md#environment-config-varsyml):

- `gitaly_callback_internal_api_url` - Specifies the URL Gitaly uses for internal API callbacks to GitLab Shell. This should point to a reachable URL for the Gitaly nodes that resolves to the GitLab Rails nodes where Shell is deployed.

## GitLab SSH

The `git+ssh` service in GitLab allows for users to perform [Git actions such as pushes or pulls over SSH](https://docs.gitlab.com/ee/development/gitlab_shell/features.html#git-operations). There are multiple options on how to configure this service as detailed below.

### GitLab SSH Daemon

GitLab offers two server daemon options for serving Git operations over SSH - `openssh` or [`gitlab-sshd`](https://docs.gitlab.com/ee/administration/operations/gitlab_sshd.html). The latter being a bespoke offering that provides additional features.

By default, `openssh` will be used, but you can switch over to `gitlab-sshd` via the following Ansible variable in [Environment `vars.yml` file](environment_configure.md#environment-config-varsyml):

- `gitlab_shell_ssh_daemon` - Configures what SSH server daemon GitLab should set up and use for Git operations. Options are `openssh` or `gitlab-sshd`. Default is `openssh`.

### GitLab SSH Port (External / Internal)

The Toolkit allows you to configure the External and Internal ports used for serving Git operations over SSH, where external is the port users will use and internal is the port that the selected SSH daemon runs on. These can be configured via the following Ansible variables in the [Environment `vars.yml` file](environment_configure.md#environment-config-varsyml):

- `gitlab_shell_ssh_port` - The external port to be used for serving Git operations over SSH. This port will be used to configure the HAProxy external connection. Optional, default is `2222` (HAProxy External) / `22` (Single Node).
- `gitlab_shell_ssh_internal_port` - The internal port the GitLab SSH daemon is running on. This port depends on the environmental type as well as the SSH Daemon being used. For `openssh` this port should match what the system SSH is running on and for [`gitlab-sshd`](https://docs.gitlab.com/ee/administration/operations/gitlab_sshd.html#enable-gitlab-sshd) this will change whatever port the service is running on. Optional, default is `22` (`openssh`) / `2222` (`gitlab-sshd`).

>>> [!note]
When using the Toolkit's optional HAProxy External load balancer, GitLab SSH traffic runs on port `2222` by default to avoid conflicts with the system SSH service (port `22`) that Ansible requires.

The port can be changed via the `gitlab_shell_ssh_port` variable in your Terraform config. If port `22` is required for GitLab SSH, using a separate external load balancer is recommended.
>>>

## Gitlab Rails SSH Host Keys handling

By default the Toolkit will copy the SSH host keys from the first Rails node you configured and add or replace the files of the same name on each secondary Rails node. This ensures host mismatch errors aren’t thrown for your users when they hit the load balanced Rails nodes.

The locations and keys it copies from and to are depending on the SSH Daemon being used:

- `openssh` - `/etc/ssh/ssh_host_*`
- `gitlab-sshd` - `/var/opt/gitlab/gitlab-sshd/ssh_host_*`

In select circumstances it may be preferable to disable this behaviour. However please note doing do will require manual action to ensure that the keys match across all Rails nodes accordingly to avoid mismatch areas. If this is desired, the behaviour can be disabled via the following Ansible variable in the [Environment `vars.yml` file](environment_configure.md#environment-config-varsyml):

- `gitlab_shell_ssh_sync_keys` - Syncs SSH keys between all Rails nodes. This should only be disabled in select circumstances and doing so will require manual syncing of all keys to prevent mismatch errors. Optional, default is `true`.

## Advanced Search

The Toolkit supports automatically setting up GitLab's [Advanced Search](https://docs.gitlab.com/ee/integration/advanced_search/elasticsearch.html) functionality. This includes optionally provisioning and configuring [OpenSearch](https://opensearch.org/) nodes as a convenience to be a cluster as well as configuring GitLab to use it.

> [!note]
> To be able to enable Advanced Search you'll require at least a GitLab Premium License, or a Free tier instance enrolled in the [Registration Features program](https://docs.gitlab.com/ee/administration/settings/usage_statistics.html#registration-features-program).

Due to the nature of OpenSearch it's not possible to give specific guidance on what size and shape the cluster should take as it's heavily dependent on aspects such as data or expected usage. That being said [some guidance for Elasticsearch that also applies to OpenSearch can be found in our Advanced Search documentation](https://docs.gitlab.com/ee/integration/advanced_search/elasticsearch.html#guidance-on-choosing-optimal-cluster-configuration).

Enabling Advanced Search on your environment is designed to be as easy possible and can be done as follows:

- OpenSearch nodes should be provisioned as normal via Terraform.
- Once the nodes are available Ansible will automatically configure them, downloading and setting up the OpenSearch Docker image.
  - To deploy a specific version you can set the `opensearch_version` variable in Ansible accordingly. Otherwise, the Toolkit deploys the latest supported version.
- Ansible will then configure the GitLab environment near the end of its run to enable Advanced Search against those nodes and perform the first index.
  - If it's desired to complete indexing before enabling the search feature (e.g. for large datasets that may require long indexing times), set the `advanced_search_enable` variable to `false`. Indexing will be started while the search feature is still disabled. Once indexing is complete, set `advanced_search_enable` to `true` (or remove the variable to use the default setting) and run Ansible again to enable search.

### Advanced Search Config Options

The following options are available to manage how Advanced Search is configured in the GitLab environment:

#### Advanced Search Custom Config

It's possible to pass additional custom configuration for Advanced Search through the `advanced_search_custom_config` variable. This allows you to configure any valid [GitLab Advanced Search setting](https://docs.gitlab.com/ee/integration/advanced_search/elasticsearch.html#advanced-search-configuration) beyond the default ones set by the Toolkit, for example:

```yaml
advanced_search_custom_config:
 elasticsearch_indexed_file_size_limit_kb: 10240
 elasticsearch_indexed_field_length_limit: 20000
 elasticsearch_max_bulk_size_mb: 100
 elasticsearch_max_bulk_concurrency: 10
```

> [!warning]
Custom configuration is only applied during the initial Advanced Search setup or when `advanced_search_reconfigure` is `true`. This prevents overriding settings that have subsequently been manually configured through the GitLab UI, but also means your custom configuration may not be applied if you add it after initial setup without enabling `advanced_search_reconfigure`.

#### Advanced Search Reconfigure

The `advanced_search_reconfigure` variable can be used to force a complete reconfiguration of Advanced Search:

```yml
advanced_search_reconfigure: true
```

When enabled, this will reset and reapply the Advanced Search config, including Custom Config, along with performing a full reindex.

> [!warning]
This operation will delete the existing search index and search functionality will be unavailable during re-indexing, which can take significant time depending on your data size.

## Container Registry

The Toolkit can configure the [GitLab Container Registry](https://docs.gitlab.com/ee/user/packages/container_registry/) when [External SSL](environment_advanced_ssl.md#external-ssl) is enabled. Since this fork does not provision managed Object Storage (Nutanix has no equivalent module support for this), Object Storage for the registry must be configured separately via [Custom Config](#custom-config), the same as other object storage buckets - see [Custom Servers (On Prem)](#custom-servers-on-prem) for the pattern this follows.

The registry is configured to run on the subdomain `registry.<external_host>` by default, where `external_host` is the hostname configured via the `external_url` setting. For example, if an environment was configured with `external_url` set to `https://gitlab.test.com` the registry will be made available on `https://registry.gitlab.test.com`.

The below settings configure how the service and dependents are set up:

- `container_registry_enable` - Controls whether the container registry and dependents are enabled. Optional, default is `false` - must be explicitly enabled since Object Storage isn't managed by Terraform on Nutanix.
- `container_registry_external_url` - The URL registry will be available on. Optional, default is `https://registry.<external_host>`.
- `gitlab_object_storage_registry_chunksize_mb` - The registry chunksize for multi-part uploads. Consider increasing it somewhere between 25 and 50 if experiencing failures with large images, see [GitLab documentation](https://docs.gitlab.com/ee/administration/packages/container_registry.html#aws-s3-with-the-gitlab-registry-error-when-pushing-large-images) for more information. Optional, default is `5`.

> [!note]
> When configuring [External SSL with user provided certificates](environment_advanced_ssl.md#user-provided-certificates), the URL configured via `container_registry_external_url` must be included as a Subject Alternative Name (SAN) name.

### Container Registry Metadata Database

The Toolkit can be configured to deploy the [Container Registry Metadata Database](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/).

>>> [!warning] Container Registry Metadata Database limitations
Take note of the following limitations when using the Container Registry Metadata Database:

- The metadata database can only be deployed when using a single GitLab managed Postgres instance, when using an externally managed database for all of GitLab, or when the registry database is configured on a separate externally managed database via `container_registry_database_host`. The registry database cannot be co-located on the Linux package HA Postgres cluster, which only supports the main GitLab database.
- The database can be deployed alongside the main GitLab database, but for Geo deployments the database must be located separately.
- The metadata database was introduced in 17.5, but due to changes in the process and config, the Toolkit only supports from 18.3 onwards.
>>>

The following settings are available to enable the metadata database:

- `container_registry_database_configure` - Should the metadata database be configured by the Toolkit. Defaults to `false`.
- `container_registry_database_enabled` - Should the database be enabled, this will default to `false` to allow for the import process to be completed. Can be set to `true` when being deployed to a new instance.

The below settings are required when using an externally managed database:

- `container_registry_database_host` - Host for the metadata database. Will default to the main GitLab database instance.
- `container_registry_database_port` - The port of the PostgreSQL instance. Should only be changed if the instance isn't running with the default port. Default is `5432`.
- `container_registry_database_name` - Name of the database to be created and used for the metadata database. Defaults to `registry`.
- `container_registry_database_admin_username` - The admin user to authenticate with the PostgreSQL instance. Required when using a different instance than the main GitLab database.
- `container_registry_database_admin_password` - The admin users password for authentication with the PostgreSQL instance. Required when using a different instance than the main GitLab database.
- `container_registry_login_database` - The initial database that the Toolkit connects to when creating the new user. Defaults to `template1`.
- `container_registry_maintenance_database` - The initial database that the Toolkit connects to when creating the new database. Defaults to `postgres`.
- `container_registry_database_username` - Username for the user to be created and used for authentication by GitLab with the metadata database. Defaults to `registry`.
- `container_registry_database_password` - Password for the metadata database user being created for authentication by GitLab with the metadata database.
- `container_registry_database_ssl_mode` - See the PostgreSQL documentation for additional information https://www.postgresql.org/docs/17/libpq-ssl.html. Defaults to `prefer`. If certificates need to be provided this should be done via [custom config](environment_advanced.md#custom-config).

> [!note]
> When deploying the metadata database for a new deployment the the database can be enabled straight away. For existing deployments, the database should be disabled initially so that the required import process can be followed, once complete the database can be enabled.

## GitLab Pages

The Toolkit can configure [GitLab Pages](https://docs.gitlab.com/administration/pages/) with wildcard domains for Linux Package (Omnibus) environments. The settings to configure this are as follows:

- `pages_external_url` -  [Wildcard URL root](https://docs.gitlab.com/ee/administration/pages/index.html#wildcard-domains) that will be used to serve Pages content for this instance. Provided as a URL format including protocol, e.g. `https://pages.example.io`. Specifying HTTPS protocol will enable wildcard SSL, and require `pages_ssl_cert_file` and `pages_ssl_key_file` to be specified. **Required**.
- `pages_ssl_cert_file` - Path to SSL certificate file for the Pages daemon to serve. Must be specified with `pages_ssl_key_file`. Required if `pages_external_url` protocol is HTTPS. Certificate must meet [the following requirements](https://docs.gitlab.com/ee/administration/pages/index.html#wildcard-domains-with-tls-support).
  - `pages_ssl_cert` - An alternative to `pages_ssl_cert_file` if the certificate is not stored in a local file, to pass the certificate contents directly to Ansible. Use `pages_ssl_cert`, or `pages_ssl_cert_file`, but not both. This approach can be used to retrieve the certificate via a lookup.
- `pages_ssl_key_file` - Path to key file for SSL certificate that the Pages daemon will serve. Must be specified with `pages_ssl_cert_file`. Required if `pages_external_url` protocol is HTTPS.
  - `pages_ssl_key` - An alternative to `pages_ssl_key_file` if the private key is not stored in a local file, to pass the private key contents directly to Ansible. Use `pages_ssl_key`, or `pages_ssl_key_file`, but not both. This approach can be used to retrieve the private key via a lookup.

GitLab Pages has [numerous configuration options](https://docs.gitlab.com/administration/pages/#global-settings) beyond the core setup that the Toolkit provides.
For additional Pages settings such as access control, single-domain setup, or other customizations, use the Toolkit's [Custom Config](#custom-config) and [Custom Tasks](#custom-tasks) features.

## Custom Servers (On Prem)

In addition to Nutanix, there is partial support for configuring Custom Servers (e.g. On prem servers running locally in your network) with Ansible via a [Static Inventory](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html).

>>> [!important]
[Support for this feature is limited](https://support.gitlab.com/hc/en-us/articles/11625911285404-Statement-of-Support#gitlab-environment-toolkit) due to the vast potential number of permutations.

In particular, be aware of the following important callouts:

- Custom servers must follow the basic [requirements](../README.md#requirements).
- **Custom servers must have basic security hardening in place throughout**. The GitLab configuration generated by Ansible assumes that this hardening is in place, such as host firewalls configured to only allow standard external facing ports (22 for SSH, 80/443 for HTTP/HTTPS) with all other ports blocked by default. Additionally, you should review all [security considerations](environment_post_considerations.md) as per your requirements.
- Terraform support is not available. VMs and services must be provisioned separately.
- [Object Storage](https://docs.gitlab.com/ee/administration/object_storage.html) config must be configured via [Custom Config](#custom-config) on any GitLab Rails or Sidekiq nodes.
- Data Disks configuration is not supported. These must be configured separately.
>>>

To configure Custom Servers with Ansible the setup process involves the following:

1. Creating a Static Inventory file
1. Generating the Facts Cache
1. Configuring the [Environment `vars.yml` file](environment_configure.md#environment-config-varsyml)

Refer to each section below for how to do each:

### Static Config

First an [Ansible Static Inventory](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html) is required instead of a [Dynamic Inventory](environment_configure.md#configure-dynamic-inventory).

Using the same recommended structure the Static Inventory file should be saved in the inventory folder, e.g. `environments/<env_name>/inventory` alongside the [Environment `vars.yml` file](environment_configure.md#environment-config-varsyml). Several file formats are supported by Ansible but for consistency we'll use `yml` format.

#### Environment Config

Configuring the environment config `vars.yml` file is [much the same as it would be normally](environment_configure.md#environment-config-varsyml) with the following differences:

- `cloud_provider` **must** be set to `none`. This should be set when running with any static inventory.
- Any Nutanix-specific variables, such as `cluster_uuid`, should be removed.
- `prefix` can also be removed.

#### Inventory Examples

An example of a 10k environment's static inventory file that's Toolkit compatible is below but note the following:

- All text in `<>` brackets should be replaced accordingly with the IP addresses that Ansible can access
- Group names (e.g. `gitaly`) and Inventory Hostnames (e.g. `gitlab-gitaly-1`) should not be replaced. These are required internally by Ansible to help correctly identify hosts.

<details><summary>10k Static Inventory</summary>

```yml
all:
  children:
    consul:
      hosts:
        gitlab-consul-1:
          ansible_host: <CONSUL-1-ADDRESS>
        gitlab-consul-2:
          ansible_host: <CONSUL-2-ADDRESS>
        gitlab-consul-3:
          ansible_host: <CONSUL-3-ADDRESS>
    gitaly:
      children:
        gitaly_primary:
          hosts:
            gitlab-gitaly-1:
              ansible_host: <GITALY-1-ADDRESS>
        gitaly_secondary:
          hosts:
            gitlab-gitaly-2:
              ansible_host: <GITALY-2-ADDRESS>
            gitlab-gitaly-3:
              ansible_host: <GITALY-3-ADDRESS>
    gitlab_nfs:
      hosts:
        gitlab-nfs-1:
          ansible_host: <GITLAB-NFS-1-ADDRESS>
    gitlab_rails:
      children:
        gitlab_rails_primary:
          hosts:
            gitlab-rails-1:
              ansible_host: <GITLAB-RAILS-1-ADDRESS>
        gitlab_rails_secondary:
          hosts:
            gitlab-rails-2:
              ansible_host: <GITLAB-RAILS-2-ADDRESS>
            gitlab-rails-3:
              ansible_host: <GITLAB-RAILS-3-ADDRESS>
    haproxy_external:
      hosts:
        gitlab-haproxy-external-1:
          ansible_host: <HAPROXY-EXTERNAL-1-ADDRESS>
    haproxy_internal:
      hosts:
        gitlab-haproxy-internal-1:
          ansible_host: <HAPROXY-INTERNAL-1-ADDRESS>
    monitor:
      hosts:
        gitlab-monitor-1:
          ansible_host: <MONITOR-1-ADDRESS>
    pgbouncer:
      hosts:
        gitlab-pgbouncer-1:
          ansible_host: <PGBOUNCER-1-ADDRESS>
        gitlab-pgbouncer-2:
          ansible_host: <PGBOUNCER-2-ADDRESS>
        gitlab-pgbouncer-3:
          ansible_host: <PGBOUNCER-3-ADDRESS>
    postgres:
      children:
        postgres_primary:
          hosts:
            gitlab-postgres-1:
              ansible_host: <POSTGRES-1-ADDRESS>
        postgres_secondary:
          hosts:
            gitlab-postgres-2:
              ansible_host: <POSTGRES-2-ADDRESS>
            gitlab-postgres-3:
              ansible_host: <POSTGRES-3-ADDRESS>
    praefect:
      children:
        praefect_primary:
          hosts:
            gitlab-praefect-1:
              ansible_host: <PRAEFECT-1-ADDRESS>
        praefect_secondary:
          hosts:
            gitlab-praefect-2:
              ansible_host: <PRAEFECT-2-ADDRESS>
            gitlab-praefect-3:
              ansible_host: <PRAEFECT-3-ADDRESS>
    praefect_postgres:
      children:
        praefect_postgres_primary:
          hosts:
            gitlab-praefect-postgres-1:
              ansible_host: <PRAEFECT-POSTGRES-1-ADDRESS>
    redis_cache:
      children:
        redis_cache_primary:
          hosts:
            gitlab-redis-cache-1:
              ansible_host: <REDIS-CACHE-1-ADDRESS>
        redis_cache_secondary:
          hosts:
            gitlab-redis-cache-2:
              ansible_host: <REDIS-CACHE-2-ADDRESS>
            gitlab-redis-cache-3:
              ansible_host: <REDIS-CACHE-3-ADDRESS>
    redis_persistent:
      children:
        redis_persistent_primary:
          hosts:
            gitlab-redis-persistent-1:
              ansible_host: <REDIS-PERSISTENT-1-ADDRESS>
        redis_persistent_secondary:
          hosts:
            gitlab-redis-persistent-2:
              ansible_host: <REDIS-PERSISTENT-2-ADDRESS>
            gitlab-redis-persistent-3:
              ansible_host: <REDIS-PERSISTENT-3-ADDRESS>
    sidekiq:
      children:
        sidekiq_primary:
          hosts:
            gitlab-sidekiq-1:
              ansible_host: <SIDEKIQ-1-ADDRESS>
        sidekiq_secondary:
          hosts:
            gitlab-sidekiq-2:
              ansible_host: <SIDEKIQ-2-ADDRESS>
            gitlab-sidekiq-3:
              ansible_host: <SIDEKIQ-3-ADDRESS>
            gitlab-sidekiq-4:
              ansible_host: <SIDEKIQ-4-ADDRESS>
    ungrouped:
```

</details>

For smaller environments where Redis is combined it would look as follows:

<details><summary>Redis Static Inventory</summary>

```yml
all:
  children:
    redis:
      children:
        redis_primary:
          hosts:
            gitlab-redis-1:
              ansible_host: <REDIS-1-ADDRESS>
        redis_secondary:
          hosts:
            gitlab-redis-2:
              ansible_host: <REDIS-2-ADDRESS>
            gitlab-redis-3:
              ansible_host: <REDIS-3-ADDRESS>
```

</details>

For environments with OpenSearch nodes, the static inventory should have OpenSearch hosts information:

<details><summary>OpenSearch Static Inventory</summary>

```yml
all:
  children:
    opensearch:
      children:
        opensearch_primary:
          hosts:
            gitlab-opensearch-1:
              ansible_host: <OPENSEARCH-1-ADDRESS>
        opensearch_secondary:
          hosts:
            gitlab-opensearch-2:
              ansible_host: <OPENSEARCH-2-ADDRESS>
            gitlab-opensearch-3:
              ansible_host: <OPENSEARCH-3-ADDRESS>
```

</details>

For environments with Geo, the static inventory will need to follow the below example:

<details><summary>Geo Static Inventory</summary>

```yml
all:
  children:
    <GEO_(PRIMARY/SECONDARY)_SITE_GROUP_NAME>:
      hosts:
        <PREFIX>-consul-1:
          ansible_host: <CONSUL-1-ADDRESS>
        <PREFIX>-consul-2:
          ansible_host: <CONSUL-2-ADDRESS>
        <PREFIX>-consul-3:
          ansible_host: <CONSUL-3-ADDRESS>
        <PREFIX>-gitaly-1:
          ansible_host: <GITALY-1-ADDRESS>
        <PREFIX>-gitaly-2:
          ansible_host: <GITALY-2-ADDRESS>
        <PREFIX>-gitaly-3:
          ansible_host: <GITALY-3-ADDRESS>
        <PREFIX>-gitlab-rails-1:
          ansible_host: <GITLAB-RAILS-1-ADDRESS>
        <PREFIX>-gitlab-rails-2:
          ansible_host: <GITLAB-RAILS-2-ADDRESS>
        <PREFIX>-gitlab-rails-3:
          ansible_host: <GITLAB-RAILS-3-ADDRESS>
        <PREFIX>-haproxy-external-1:
          ansible_host: <HAPROXY-EXTERNAL-1-ADDRESS>
        <PREFIX>-haproxy-internal-1:
          ansible_host: <HAPROXY-INTERNAL-1-ADDRESS>
        <PREFIX>-monitor-1:
          ansible_host: <MONITOR-1-ADDRESS>
        <PREFIX>-pgbouncer-1:
          ansible_host: <PGBOUNCER-1-ADDRESS>
        <PREFIX>-pgbouncer-2:
          ansible_host: <PGBOUNCER-2-ADDRESS>
        <PREFIX>-pgbouncer-3:
          ansible_host: <PGBOUNCER-3-ADDRESS>
        <PREFIX>-postgres-1:
          ansible_host: <POSTGRES-1-ADDRESS>
        <PREFIX>-postgres-2:
          ansible_host: <POSTGRES-2-ADDRESS>
        <PREFIX>-postgres-3:
          ansible_host: <POSTGRES-3-ADDRESS>
        <PREFIX>-praefect-1:
          ansible_host: <PRAEFECT-1-ADDRESS>
        <PREFIX>-praefect-2:
          ansible_host: <PRAEFECT-2-ADDRESS>
        <PREFIX>-praefect-3:
          ansible_host: <PRAEFECT-3-ADDRESS>
        <PREFIX>-praefect-postgres-1:
          ansible_host: <PRAEFECT-POSTGRES-1-ADDRESS>
        <PREFIX>-redis-1:
          ansible_host: <REDIS-1-ADDRESS>
        <PREFIX>-redis-2:
          ansible_host: <REDIS-2-ADDRESS>
        <PREFIX>-redis-3:
          ansible_host: <REDIS-3-ADDRESS>
        <PREFIX>-sidekiq-1:
          ansible_host: <SIDEKIQ-1-ADDRESS>
        <PREFIX>-sidekiq-2:
          ansible_host: <SIDEKIQ-2-ADDRESS>
        <PREFIX>-sidekiq-3:
          ansible_host: <SIDEKIQ-3-ADDRESS>
        <PREFIX>-sidekiq-4:
          ansible_host: <SIDEKIQ-4-ADDRESS>
    <GEO_(PRIMARY/SECONDARY)_SITE_GROUP_NAME>_gitlab_rails_primary:
      hosts:
        <PREFIX>-gitlab-rails-1:
          ansible_host: <GITLAB-RAILS-1-ADDRESS>
    <GEO_(PRIMARY/SECONDARY)_SITE_GROUP_NAME>_gitlab_rails_secondary:
      hosts:
        <PREFIX>-gitlab-rails-2:
          ansible_host: <GITLAB-RAILS-2-ADDRESS>
        <PREFIX>-gitlab-rails-3:
          ansible_host: <GITLAB-RAILS-3-ADDRESS>
    <GEO_(PRIMARY/SECONDARY)_SITE_GROUP_NAME>_haproxy_internal_primary:
      hosts:
        <PREFIX>-haproxy-internal-1:
          ansible_host: <POSTGRES-1-ADDRESS>
    <GEO_(PRIMARY/SECONDARY)_SITE_GROUP_NAME>_postgres_primary:
      hosts:
        <PREFIX>-postgres-1:
          ansible_host: <POSTGRES-1-ADDRESS>
    <GEO_(PRIMARY/SECONDARY)_SITE_GROUP_NAME>_postgres_secondary:
      hosts:
        <PREFIX>-postgres-2:
          ansible_host: <POSTGRES-2-ADDRESS>
        <PREFIX>-postgres-3:
          ansible_host: <POSTGRES-3-ADDRESS>
    <GEO_(PRIMARY/SECONDARY)_SITE_GROUP_NAME>_sidekiq_primary:
      hosts:
        <PREFIX>-sidekiq-1:
          ansible_host: <SIDEKIQ-1-ADDRESS>
    <GEO_(PRIMARY/SECONDARY)_SITE_GROUP_NAME>_sidekiq_secondary:
      hosts:
        <PREFIX>-sidekiq-2:
          ansible_host: <SIDEKIQ-2-ADDRESS>
        <PREFIX>-sidekiq-3:
          ansible_host: <SIDEKIQ-3-ADDRESS>
        <PREFIX>-sidekiq-4:
          ansible_host: <SIDEKIQ-4-ADDRESS>
    consul:
      hosts:
        <PREFIX>-consul-1:
          ansible_host: <CONSUL-1-ADDRESS>
        <PREFIX>-consul-2:
          ansible_host: <CONSUL-2-ADDRESS>
        <PREFIX>-consul-3:
          ansible_host: <CONSUL-3-ADDRESS>
    gitaly:
      children:
        gitaly_primary:
          hosts:
            <PREFIX>-gitaly-1:
              ansible_host: <GITALY-1-ADDRESS>
        gitaly_secondary:
          hosts:
            <PREFIX>-gitaly-2:
              ansible_host: <GITALY-2-ADDRESS>
            <PREFIX>-gitaly-3:
              ansible_host: <GITALY-3-ADDRESS>
    gitlab_rails:
      children:
        gitlab_rails_primary:
          hosts:
            <PREFIX>-gitlab-rails-1:
              ansible_host: <GITLAB-RAILS-1-ADDRESS>
        gitlab_rails_secondary:
          hosts:
            <PREFIX>-gitlab-rails-2:
              ansible_host: <GITLAB-RAILS-2-ADDRESS>
            <PREFIX>-gitlab-rails-3:
              ansible_host: <GITLAB-RAILS-3-ADDRESS>
    haproxy_external:
      hosts:
        <PREFIX>-haproxy-external-1:
          ansible_host: <HAPROXY-EXTERNAL-1-ADDRESS>
    haproxy_internal:
      hosts:
        <PREFIX>-haproxy-internal-1:
          ansible_host: <HAPROXY-INTERNAL-1-ADDRESS>
    monitor:
      hosts:
        gitlab-monitor-1:
          ansible_host: <MONITOR-1-ADDRESS>
    pgbouncer:
      hosts:
        gitlab-pgbouncer-1:
          ansible_host: <PGBOUNCER-1-ADDRESS>
        gitlab-pgbouncer-2:
          ansible_host: <PGBOUNCER-2-ADDRESS>
        gitlab-pgbouncer-3:
          ansible_host: <PGBOUNCER-3-ADDRESS>
    postgres:
      children:
        postgres_primary:
          hosts:
            <PREFIX>-postgres-1:
              ansible_host: <POSTGRES-1-ADDRESS>
        postgres_secondary:
          hosts:
            <PREFIX>-postgres-2:
              ansible_host: <POSTGRES-2-ADDRESS>
            <PREFIX>-postgres-3:
              ansible_host: <POSTGRES-3-ADDRESS>
    praefect:
      children:
        praefect_primary:
          hosts:
            gitlab-praefect-1:
              ansible_host: <PRAEFECT-1-ADDRESS>
        praefect_secondary:
          hosts:
            gitlab-praefect-2:
              ansible_host: <PRAEFECT-2-ADDRESS>
            gitlab-praefect-3:
              ansible_host: <PRAEFECT-3-ADDRESS>
    praefect_postgres:
      children:
        praefect_postgres_primary:
          hosts:
            gitlab-praefect-postgres-1:
              ansible_host: <PRAEFECT-POSTGRES-1-ADDRESS>
    redis:
      children:
        redis_primary:
          hosts:
            <PREFIX>-redis-1:
              ansible_host: <REDIS-1-ADDRESS>
        redis_secondary:
          hosts:
            <PREFIX>-redis-2:
              ansible_host: <REDIS-2-ADDRESS>
            <PREFIX>-redis-3:
              ansible_host: <REDIS-3-ADDRESS>
    sidekiq:
      children:
        sidekiq_primary:
          hosts:
            <PREFIX>-sidekiq-1:
              ansible_host: <SIDEKIQ-1-ADDRESS>
        sidekiq_secondary:
          hosts:
            <PREFIX>-sidekiq-2:
              ansible_host: <SIDEKIQ-2-ADDRESS>
            <PREFIX>-sidekiq-3:
              ansible_host: <SIDEKIQ-3-ADDRESS>
            <PREFIX>-sidekiq-4:
              ansible_host: <SIDEKIQ-4-ADDRESS>
    ungrouped:
```

</details>

For any hosts you explicitly wish for the Toolkit to ignore you can place them in the `get_ignored` group, which the Toolkit will then proceed to ignore:

<details><summary>Inventory with explicitly ignored <code>get_ignored</code> group</summary>

```yml
all:
  children:
    get_ignored:
      hosts:
        host-1:
          ansible_host: <HOST-1-ADDRESS>
        host-2:
          ansible_host: <HOST-2-ADDRESS>
```

</details>

When using external or managed services, remove the corresponding node groups from your static inventory (PostgreSQL, PgBouncer, and Consul for external databases; Redis groups for external Redis).

## System Packages

The Toolkit will install system packages on every node it requires for setting up GitLab.

In addition to this it will configure automated security upgrades and can optionally go further and run full package upgrades if desired. Refer to each section below for more information.

### Automatic Security Upgrades

The Toolkit will set up automatic security upgrades as a convenience on the target OS as follows:

- Ubuntu,  Debian - Unattended Upgrades
- RHEL 9/10, Amazon Linux 2023 - DNF Automatic

The role(s) configure the following:

- Security updates will be installed at least once per day
- The Toolkit will also run the same updates directly whenever it's run
- Automatic reboots are disabled to ensure runtime

If this behaviour is not desired you can disable this by setting the `system_packages_auto_security_upgrade` variable to `false` (can also be set via environment variable `SYSTEM_PACKAGES_AUTO_SECURITY_UPGRADE`). Note if setting this after it was previously configured the `unattended-upgrades` or `dnf-automatic` package will still need to be purged manually on affected boxes.

### Optional Package Maintenance

The Toolkit can also optionally upgrade all packages and clean up unneeded packages on your nodes on each run. The following settings control this behaviour and can be set in your Ansible environment config file (`vars.yml`) if desired:

- `system_packages_upgrade`: Configures the Toolkit to upgrade all packages on nodes. Default is `false`. Can also be set as via the environment variable `SYSTEM_PACKAGES_UPGRADE`.
- `system_packages_autoremove`: Configures the Toolkit to autoremove any old or unneeded packages on nodes. Default is `false`. Can also be set as via the environment variable `SYSTEM_PACKAGES_AUTOREMOVE`.

### Extra Packages for Enterprise Linux (EPEL)

EPEL setup can optionally be configured on RHEL-family hosts via `vars.yml` for deployments that require it for packages outside of the toolkit's own package list:

- `epel_setup`: Configures the toolkit to install the EPEL GPG Key and repository. Default is `false`.

When `epel_setup` is `true` the toolkit installs from the public [Fedora Project release URLs](https://docs.fedoraproject.org/en-US/epel/getting-started/#_release_package_permalinks) for the appropriate distribution major version. If those URLs are not reachable the following variables can be used to override them:

- `epel_gpg_key_url`: URL to install the EPEL GPG Key from. Default is `https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-{{ ansible_facts['distribution_major_version'] }}`.
- `epel_rpm_url`: URL to install the EPEL repository from. Default is `https://dl.fedoraproject.org/pub/epel/epel-release-latest-{{ ansible_facts['distribution_major_version'] }}.noarch.rpm`.

## NFS for Object Data

You can optionally provision and configure a [NFS server if desired to handle Object Data](https://docs.gitlab.com/ee/administration/nfs.html). This is not recommended however with [Object Storage](https://docs.gitlab.com/ee/administration/object_storage.html) instead preferable in all cases. To configure this some steps are required in Terraform and Ansible.

In Terraform, you'll need to provision a `gitlab_nfs` node in your [`environment.tf`](environment_provision.md#configure-module-settings-environmenttf) file. For example:

```tf
module "gitlab_ref_arch_nutanix" {
  source = "../../modules/gitlab_ref_arch_nutanix"

  [...]

  gitlab_nfs_node_count = 1
  gitlab_nfs_size = {
    num_sockets          = 4
    num_vcpus_per_socket = 1
    memory_size_mib      = 8192
  }
}
```

Then in Ansible you need to configure the `gitlab_object_storage_type` variable to `nfs` in your [`vars.yml`](environment_configure.md#environment-config-varsyml) file:

```yml
gitlab_object_storage_type: 'nfs'
```

The NFS export is restricted to exactly the nodes in the `gitlab_rails` and `sidekiq` inventory groups, which are the only nodes that mount the share. No other nodes are granted access.

### NFS User and Group IDs

When using NFS for shared storage in a Linux Package HA environment, consistent user UIDs/GIDs are required to ensure correct file permissions across nodes. The Toolkit configures this automatically for core accounts, with the following options available:

- `gitlab_user_uid` / `gitlab_user_gid` - Main GitLab user (default: `9000`)
- `web_server_uid` / `web_server_gid` - Web server group for NGINX and Pages (default: `9001`)
- `registry_uid` / `registry_gid` - Container Registry user, only needed if Registry uses NFS storage instead of object storage (no default, must be explicitly set)

> [!caution]
> Changing these values on an existing environment requires [manual actions to propagate the changes](https://docs.gitlab.com/omnibus/settings/configuration/#specify-numeric-user-and-group-identifiers).

## Tags/Labels (Nutanix Categories)

Nutanix has no direct equivalent of free-form cloud provider tags/labels. Instead, the Toolkit uses Nutanix [categories](https://www.nutanix.com/) to group and identify VMs for Ansible's dynamic inventory - see the [Nutanix section](environment_provision.md#nutanix) of the Provisioning guide for details on the `gitlab_node_prefix`, `gitlab_node_type` and `gitlab_node_level` categories the module creates and applies automatically.

Custom, free-form tagging of resources beyond these categories is not currently supported by the `gitlab_ref_arch_nutanix` module.
