The GitLab Environment Toolkit supports deploying GitLab [Reference Architectures](https://docs.gitlab.com/ee/administration/reference_architectures) across various Cloud Providers and On Prem. This also includes advanced setups such as Cloud Native Hybrid, Geo, Cloud Provider Services and more.

As such, there are *dozens* of potential environment permutations the Toolkit can support, many of which requiring context that we aim to provide fully in the [documentation](../docs/).

In this section you'll find a selection of config examples of some of the more common permutations to start off with. We're not able to provide examples for every permutation, but the following should cover most bases that you can use as a reference in tandem with the documentation to build out your specific environment:

- [1k - GCP](1k_gcp) - A 1k Reference Architecture on GCP. Standalone without load balancer frontend.
- [1k - AWS](1k_aws) - A 1k Reference Architecture on AWS. Standalone with load balancer frontend.
- [2k - Azure](2k_azure) - A 2k Reference Architecture on Azure. Standalone with separated backend components.
- [3k - GCP](3k_gcp) - A 3k Reference Architecture on GCP. HA with combined Redis queues.
- [5k - Static](5k_static) - A 5k Reference Architecture on [Custom Servers](../docs/environment_advanced.md#custom-servers-on-prem) (On Prem). An environment on Custom Servers that Ansible is used to configure.
- [10k - GCP](10k_gcp) - A 10k Reference Architecture (Omnibus) on GCP. HA.
- [10k Cloud Native Hybrid - AWS](10k_hybrid_aws_services) - A 10k Reference Architecture (Cloud Native Hybrid) on AWS with Cloud Provider Services (RDS, ElastiCache, NLB). HA with select components running on Kubernetes (AWS EKS).
- [10k Cloud Native Hybrid - GCP](10k_hybrid_gcp) - A 10k Reference Architecture (Cloud Native Hybrid) on GCP. HA with select components running on Kubernetes (GCP GKE).
- [10k Geo - AWS](10k_aws_geo) - A 10k Reference Architecture (Omnibus) on AWS with Geo configured within the same region. HA with secondary Geo environment.

> [!note]
> The above examples are not an exhaustive list, just a selection. The Toolkit supports [all Reference Architectures sizes (including Cloud Native Hybrid and Geo) on GCP, AWS, Azure and On Prem](../README.md#gitlab-environment-toolkit). Refer to the [documentation](../docs/) for full details on how to configure your intended setup.

# How to use the examples

The Reference Architectures, and by extension the Toolkit, have been designed to be scalable. The config examples above can be adjusted accordingly to another as desired. The documentation goes through each configuration in full, but some common scenarios are summarised below to help:

- All variable values in the examples with surrounding `<>` brackets indicates that they should be replaced accordingly.
- Tips for making changes to an example
  - Cloud Provider - Done in all [Terraform](../docs/environment_provision.md#3-set-up-the-environments-config) and [Ansible](../docs/environment_configure.md#2-set-up-the-environments-inventory-and-config) config files throughout. In the examples most files will be switched out to match the cloud provider wholesale but the Ansible `vars.yml` file will have a few settings changed.
  - Environment Sizing - Done in the [Terraform `environment.tf` file](../docs/environment_provision.md#configure-module-settings-environmenttf) (GCP linked for example) with the corresponding Cloud Provider module variables. Corresponding type and count settings can be adjusted to match the target architecture. For example if starting with the 10k GCP but aiming for a 3k you would adjust the `gitlab_rails_machine_type` variable from `n1-highcpu-32` to `n1-highcpu-8`. Additionally, to remove nodes entirely you can remove the `type` and `count` variables for the specific component.
    - When a component is removed the Toolkit will look to set it up on the Rails node unless given config for an external resource.
  - Advanced setups - These are advanced setups. As such it's **strongly recommended going through the documentation in full** in each area for context as linked.
    - Geo - Separate environments initially and then configuring Geo settings in each and following the process as given. Documentation largely remains the same for these setups except for parts that are Cloud Provider specific, such as AWS RDS replication for example. [Documentation](../docs/geo/geo_advanced.md)
    - Cloud Native Hybrid - Replacing the equivalent Omnibus components in the Terraform config (Rails, Sidekiq, Monitor, External Load Balancer) with the equivalent Kubernetes variables. [Documentation](../docs/environment_advanced_hybrid.md).
    - Cloud Provider Services - Replacing the equivalent Omnibus components in the Terraform config (Load Balancer(s), Postgres + PgBouncer + Consul, Redis) with the equivalent Cloud Provider service variables. [Documentation](../docs/environment_advanced_services.md).
