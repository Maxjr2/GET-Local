The GitLab Environment Toolkit supports deploying GitLab [Reference Architectures](https://docs.gitlab.com/ee/administration/reference_architectures) on Nutanix AHV (via Terraform) and On Prem/Custom Servers (via Ansible static inventory). See [Supported Cloud Providers](../TECHNICAL_DESIGN.md#supported-cloud-providers) for this fork's scope.

As such, there are *dozens* of potential environment permutations the Toolkit can support, many of which requiring context that we aim to provide fully in the [documentation](../docs/).

In this section you'll find a selection of config examples to start off with. We're not able to provide examples for every permutation, but the following should cover most bases that you can use as a reference in tandem with the documentation to build out your specific environment:

- [1k - Nutanix](1k_nutanix) - A 1k Reference Architecture on Nutanix AHV. Standalone, single GitLab Rails node.
- [1k Geo - Static](1k_static_geo) - A 1k Reference Architecture on [Custom Servers](../docs/environment_advanced.md#custom-servers-on-prem) (On Prem) with Geo configured. An environment on Custom Servers that Ansible is used to configure.
- [5k - Static](5k_static) - A 5k Reference Architecture on [Custom Servers](../docs/environment_advanced.md#custom-servers-on-prem) (On Prem). An environment on Custom Servers that Ansible is used to configure.

> [!note]
> The above examples are not an exhaustive list, just a selection. Refer to the [documentation](../docs/) for full details on how to configure your intended setup, and the [Nutanix Deployment Guide](../docs/environment_nutanix_deployment_guide.md) for a complete end-to-end walkthrough.

# How to use the examples

The Reference Architectures, and by extension the Toolkit, have been designed to be scalable. The config examples above can be adjusted accordingly to another as desired. The documentation goes through each configuration in full, but some common scenarios are summarised below to help:

- All variable values in the examples with surrounding `<>` brackets indicates that they should be replaced accordingly.
- Tips for making changes to an example
  - Environment Sizing - Done in the [Terraform `environment.tf` file](../docs/environment_provision.md#configure-module-settings-environmenttf) with the corresponding `gitlab_ref_arch_nutanix` module variables. Corresponding `*_node_count`/`*_size` settings can be adjusted to match the target architecture. Additionally, to remove nodes entirely you can set the `*_node_count` variable for the specific component to `0`.
    - When a component is removed the Toolkit will look to set it up on the Rails node unless given config for an external resource.
  - Geo - Separate environments initially and then configuring Geo settings in each and following the process as given. [Documentation](../docs/geo/geo_advanced.md)
