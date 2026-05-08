# GitLab Environment Toolkit

![alt text](https://gitlab.com/uploads/-/system/project/avatar/14292404/tanuki-blueprint.png "GitLab Environment Toolkit")

The GitLab Environment Toolkit (`GET`) automates deploying and managing scaled GitLab environments following the [Reference Architectures](https://docs.gitlab.com/ee/administration/reference_architectures). Using Terraform for infrastructure provisioning and Ansible for configuration, the Toolkit handles the full lifecycle of a GitLab deployment, from initial setup through upgrades, across cloud providers, on-prem, or a mix of both.

**New to the Toolkit?** Follow the [Quick Start Guide](docs/environment_quick_start_guide.md) for a complete walkthrough deploying a 10k environment on AWS.

## Before You Start

The Toolkit can help with deploying and maintaining a scaled GitLab environment, but it does not remove the underlying challenges that come with running large production applications. Environments remain the responsibility of the user. Following the [Shared Responsibility Model](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/TECHNICAL_DESIGN.md#shared-responsibility), the Toolkit aims to configure best practices for the GitLab application and, when using supported cloud providers, base infrastructure provisioning and configuration. Environmental responsibility, ongoing operations, and any custom infrastructure remain the user's responsibility.

Users are recommended to have a good working knowledge of Terraform, Ansible, GitLab administration and infrastructure management, and to be aware of what running such an environment entails. For teams that need a more guided deployment experience, [Professional Services](https://about.gitlab.com/services/#implementation-services) is available. For teams that want a more managed solution long-term, [GitLab SaaS](https://docs.gitlab.com/ee/subscriptions/gitlab_com/) or [GitLab Dedicated](https://about.gitlab.com/dedicated/) may be a better fit.

The Toolkit is designed around the GitLab Reference Architectures and is opinionated by design. Deploying across cloud providers, on-prem, and hybrid environments involves a large surface area, and not every infrastructure design or use case can be supported. Where the Toolkit falls short of specific requirements, [Custom Config and Tasks](docs/environment_advanced.md#custom-config) provide extension points, but some use cases may fall outside of scope entirely.

Review the Toolkit in full before any use, as it offers no guarantees on topics such as security or data integrity. [Further manual setup](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/docs/environment_post_considerations.md) after deployment may also be required.

## How It Works

The Toolkit deploys GitLab environments in two phases. In the **provisioning** phase, Terraform creates the required infrastructure per the target Reference Architecture: VMs and supporting cloud services for Linux Package environments, or a Kubernetes cluster and node pools for Cloud Native Hybrid. Resources are tagged and labelled during provisioning so that Ansible can identify each component automatically.

In the **configuration** phase, Ansible takes those tagged resources and installs and configures each component in the correct order. For Linux Package (Omnibus) deployments this means configuring each VM for its designated role. For Cloud Native Hybrid deployments this means deploying GitLab via Helm Charts or the GitLab Operator onto the Kubernetes cluster alongside any VM-backed stateful components. Both paths handle environment sizing dynamically, so the same scripts serve a single-node setup and a fully distributed multi-node deployment.

## Features

**Deployment targets:**

- All [Reference Architecture sizes](https://docs.gitlab.com/ee/administration/reference_architectures) from [1k](https://docs.gitlab.com/ee/administration/reference_architectures/1k_users.html) to [50k](https://docs.gitlab.com/ee/administration/reference_architectures/50k_users.html) users
- Linux Package (Omnibus) deployments on GCP, AWS and Azure; on-prem and custom servers also supported via Ansible static inventory (see [supported providers](TECHNICAL_DESIGN.md#supported-cloud-providers))
- Cloud Native Hybrid via Helm Charts or Operator; Kubernetes cluster provisioning on GCP (GKE) and AWS (EKS)

**Architecture and operations:**

- [Geo](docs/geo/README.md) multi-site deployments
- Upgrades including [Zero Downtime Upgrades](docs/environment_upgrades.md)
- Advanced Search with OpenSearch

**Components:**

- Container Registry
- SSL/TLS support
- Built-in Load Balancing and Monitoring (Prometheus)
- Cloud Services for PostgreSQL, Redis and Load Balancers
- Custom Config, Tasks and Files for extending beyond toolkit defaults

## Requirements

**Control Node:**

- Terraform `1.13.0` and upwards
- Ansible `13.0` (ansible-core `2.20`, Python `3.12`+)
  - All [currently maintained Ansible versions](https://docs.ansible.com/ansible/latest/reference_appendices/release_and_maintenance.html) supported
  - Older versions supported for deprecated target OS compatibility - see [Target Operating System Support](docs/environment_configure.md#target-node-operating-system-support)

**Target Nodes:**

- GitLab version: `16.0.0` and upwards
- Linux Package (Omnibus):
  - OS: Ubuntu 22.04/24.04, Debian 11/12/13, RHEL 9/10, Amazon Linux 2023
  - Deprecated OS versions supported with older Ansible versions - see [Target Operating System Support](docs/environment_configure.md#target-node-operating-system-support)
  - OS support depends on both [Linux Package (Omnibus)](https://docs.gitlab.com/administration/package_information/supported_os/) and Ansible compatibility
  - Clean OS installations only; admin access required to install dependencies
  - ARM-based hardware supported where upstream packages are available
- Kubernetes (Cloud Native): any [currently supported Kubernetes version](https://endoflife.date/kubernetes)

## Documentation

**Getting started:**

- [Quick Start Guide](docs/environment_quick_start_guide.md)
- [Preparing the environment](docs/environment_prep.md)
- [Provisioning with Terraform](docs/environment_provision.md)
- [Configuring with Ansible](docs/environment_configure.md)

**Advanced topics:**

- [Custom Config / Tasks / Files, Data Disks, Advanced Search, Container Registry and more](docs/environment_advanced.md)
- [Cloud Native Hybrid](docs/environment_advanced_hybrid.md)
- [Component Cloud Services / Custom (Load Balancers, PostgreSQL, Redis)](docs/environment_advanced_services.md)
- [SSL](docs/environment_advanced_ssl.md)
- [Network Setup](docs/environment_advanced_network.md)
- [Monitoring](docs/environment_advanced_monitoring.md)

**Operations:**

- [Upgrades](docs/environment_upgrades.md)
- [Considerations After Deployment - Backups, Security](docs/environment_post_considerations.md)
- [Troubleshooting](docs/environment_troubleshooting.md)

**Geo:**

- [Overview](docs/geo/README.md)
- [Provisioning with Terraform](docs/geo/geo_provision.md)
- [Configuring with Ansible](docs/geo/geo_configure.md)
- [Advanced](docs/geo/geo_advanced.md)

**Config Examples:**

[Full config examples are available for select Reference Architectures](examples).

## How To Use

The Toolkit's Terraform and Ansible components can be used in various ways depending on requirements:

- Terraform - Source (git checkout), [Docker](docs/environment_provision.md#4-run-the-gitlab-environment-toolkits-docker-container-optional), [Module Registry](docs/environment_provision.md#terraform-module-registry)
- Ansible - Source (git checkout), [Docker](docs/environment_configure.md#3-run-the-gitlab-environment-toolkits-docker-container-optional), [Collection](docs/environment_configure.md#running-with-ansible-collection-optional)

Refer to the docs above for full instructions on each.

## Support

Technical support is available for the current Toolkit major version and requests should be raised via the [Support team](https://support.gitlab.com/hc/en-us/articles/11626483177756-GitLab-Support). For detailed information about what is supported, refer to the [Statement of Support](https://support.gitlab.com/hc/en-us/articles/11625911285404-Statement-of-Support#gitlab-environment-toolkit).

Toolkit-specific bugs and issues can be raised in the [issue tracker](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/work_items).

For troubleshooting help, refer to the [Troubleshooting guide](docs/environment_troubleshooting.md).

## Feature Requests

The Toolkit is opinionated by design: deploying across cloud providers and on-prem involves a large surface area, and not all feature requests fit the approach. Where requests fall outside scope, [Custom Config](docs/environment_advanced.md#custom-config) is often the right path.

Feature requests that would benefit a broad set of users are welcome in the [issue tracker](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/work_items). Please check whether the request has already been raised before opening a new one.

### Out of Scope

Due to complexity, permutations, or areas better left to direct configuration, the following are out of scope:

- Cloud accounts management
- Observability stack beyond Prometheus
- Direct OmniAuth and Email support
- DNS server management
- Full GitLab agent server for Kubernetes (KAS) setup
- On Prem HA Load Balancers
- [Downgrades](docs/environment_upgrades.md#environment-downgrades)

## Contributions

Contributions to existing features are welcome. Refer to the [Contributing guide](CONTRIBUTING.md) for more information.

## Testing

Running the Toolkit for testing purposes can incur notable costs. Refer to the [Testing document](TESTING.md) for more information.

## Licensing

Requires [GitLab Premium](https://about.gitlab.com/pricing/) or above.

Released under the [GitLab EE license](LICENSE).
