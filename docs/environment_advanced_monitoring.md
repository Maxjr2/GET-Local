# Advanced - Monitoring

- [GitLab Environment Toolkit - Quick Start Guide](environment_quick_start_guide.md)
- [GitLab Environment Toolkit - Preparing the environment](environment_prep.md)
- [GitLab Environment Toolkit - Provisioning the environment with Terraform](environment_provision.md)
- [GitLab Environment Toolkit - Configuring the environment with Ansible](environment_configure.md)
- [GitLab Environment Toolkit - Advanced - Custom Config / Tasks / Files, Data Disks, Advanced Search, Container Registry and more](environment_advanced.md)
- [GitLab Environment Toolkit - Advanced - SSL](environment_advanced_ssl.md)
- [GitLab Environment Toolkit - Advanced - Network Setup](environment_advanced_network.md)
- [**GitLab Environment Toolkit - Advanced - Monitoring**](environment_advanced_monitoring.md)
- [GitLab Environment Toolkit - Upgrades (Toolkit, Environment)](environment_upgrades.md)
- [GitLab Environment Toolkit - Considerations After Deployment - Backups, Security](environment_post_considerations.md)
- [GitLab Environment Toolkit - Geo](geo/README.md)
  - [GitLab Environment Toolkit - Geo - Provisioning the environment with Terraform](geo/geo_provision.md)
  - [GitLab Environment Toolkit - Geo - Configuring the environment with Ansible](geo/geo_configure.md)
  - [GitLab Environment Toolkit - Geo - Advanced](geo/geo_advanced.md)
- [GitLab Environment Toolkit - Troubleshooting](environment_troubleshooting.md)

The Toolkit supports setting up optional monitoring of the environment of metrics such as CPU and Memory as well as GitLab specific metrics.

> [!note]
> The following monitoring setups are optional. You're not required to use this functionality for monitoring your environment, and you can use a different setup as desired.

The core components used are:

- [Prometheus](https://prometheus.io/) - For metrics collection and storage.
- [Consul](https://developer.hashicorp.com/consul) - Component auto-discovery.

The Toolkit will configure these in each case, including scrape config, dashboard(s).

On this page we'll detail how to deploy the monitoring setup for each environment type with the Toolkit. Head to the relevant section below depending on the type of environment you have. **It's also worth noting this guide assumes a working knowledge of Prometheus and Consul as well as being supplementary to the rest of the docs.**

[TOC]

## Omnibus

In Omnibus environments the monitoring stack is provided by [Omnibus GitLab](https://docs.gitlab.com/omnibus/), which has Prometheus and Consul built in.

In this setup, these components are deployed to their own VM named `monitor`. Like other Omnibus components this is enabled by simply deploying this node in Terraform and Ansible will configure it automatically. See the below sections for details on each.

**Terraform**

Provisioning the `monitor` node in Terraform that hosts the monitoring stack is the same as [deploying any other VM](environment_provision.md#configure-module-settings-environmenttf), for example:

```tf
module "gitlab_ref_arch_nutanix" {
  source = "../../modules/gitlab_ref_arch_nutanix"

  [...]

  monitor_node_count = 1
  monitor_size = {
    num_sockets          = 4
    num_vcpus_per_socket = 1
    memory_size_mib      = 8192
  }
```

**Ansible**

With that node provisioned, Ansible will detect it, and configure the monitoring stack automatically. It will configure the relevant metrics exporters on the component nodes, and connect them to the Prometheus instance. You can disable this behavior by specifying the following setting in your Ansible [`vars.yml`](environment_configure.md#environment-config-varsyml) file:

- `monitor_prometheus_scrape_config_setup` - Configures if any scrape configs should be configured by the Toolkit. Setting this to `false` will remove these to allow for more flexibility if desired. Optional, defaults to `true`.

You can also [customize Prometheus scrape definitions](environment_advanced_monitoring.md#omnibus-2) and [Prometheus alerting/recording rules](environment_advanced_monitoring.md#omnibus-3).

## Custom Config

Like [other areas](environment_advanced.md#custom-config) you can pass in Custom Config for the monitoring stacks also.

> [!caution]
> **This is an advanced feature, and it must be used with caution**. Any custom config passed will always take precedence and may lead to various unintended consequences or broken environments if not used carefully. This includes when setting [Scrape Config](#custom-prometheus-scrape-options) or [Rules](#custom-prometheus-rules) as detailed in later in this guide - Custom Config will always take precedence.

How this works differs depending on the environment setup used as detailed in the below sections.

### Omnibus

As Prometheus is packaged within Omnibus, [the standard approach](environment_advanced.md#linux-package-omnibus) for deploying a `monitor` node can be followed for any [valid config](https://docs.gitlab.com/ee/administration/monitoring/prometheus/).

## Custom Prometheus scrape options

There are various options available on how Prometheus can be configured to scrape its targets.

By default, the Toolkit has the following options:

- Consul auto-discovery - When Consul is deployed it will be utilised to provide auto-discovery for Prometheus. This is recommended in most cases as it can handle situations such as IPs changing.
- Static internal IPs - When Consul is not deployed, static internal IPs will be used instead.
- None - As an additional option the Toolkit can also add no scrape configs for flexibility as desired via the Ansible `monitor_prometheus_scrape_config_setup` variable.
- Custom - Additive to any of the above options, you can also pass in your own custom scrape configs as desired.

> [!note]
> If you're using [Custom Config](#custom-config) with the same variables configured it will take precedence over custom scrape options.

Scrape configs [are passed in a JSON dictionary format](https://docs.gitlab.com/ee/administration/monitoring/prometheus/#adding-custom-scrape-configurations). This is done via the following variable:

- `monitor_custom_prometheus_scrape_config` - A list of custom scrape configs to configure in JSON dictionary format.

An example of how you would configure this, in this case for an Influx DB [with exporter enabled](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#static_config), in the Ansible [`vars.yml`](environment_configure.md#environment-config-varsyml) file would be as follows:

```yml
monitor_custom_prometheus_scrape_config: |
  {
    'job_name': 'influxdb',
    'static_configs' => [
      'targets' => ["<INFLUXDB_URL>:9122"],
    ],
  },
```

## Custom Prometheus rules

The Toolkit allows for you to pass in custom alert/record rules to be used in Prometheus for the Omnibus setup described above.

By default, the Toolkit will look for rules under the `environments/<env_name>/files/prometheus` folder. In Prometheus, rules are typically organised under group folders, so the same is expected here. As such, rules should be placed in their own group folder in this path, for example `environments/<env_name>/files/prometheus/<rules group folder name>/<rule files>`. You can create multiple folders to store different rule groups or store everything in a single folder. You can also store the rules in a different location other than `environments/<env_name>/files/prometheus/` for each setup.

Once the rules are in place you can then configure the Toolkit to set these up accordingly. This is done by configuring the Toolkit to know what sub-folders of rules to transfer over.

For details on how to do this for each setup, refer to the applicable section below.

> [!note]
> If you're using [Custom Config](#custom-config) with the same variables configured it will take precedence over custom rules.

### Omnibus

For Omnibus, the following variables are used to configure custom rules:

- `monitor_custom_rules_path` - Path the Toolkit will look under for any rules. Default is `environments/<env_name>/files/prometheus`.
- `monitor_custom_rules` - List of rule folders under `monitor_custom_rules_path` the Toolkit should transfer. Each entry requires a couple of variables to be set in dict format: For each a dict should be set with the following sub-variables:
  - `folder` - The folder under `monitor_custom_rules_path` to transfer over

An example of how you would configure this for several folders in the default location would be as follows:

```yaml
monitor_custom_rules:
  - folder: 'my_sidekiq_rules'
  - folder: 'my_gitaly_rules'
```
