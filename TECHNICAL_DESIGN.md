# GitLab Environment Toolkit - Technical Design

This document serves as the Technical Design and Vision for the [GitLab Environment Toolkit](https://gitlab.com/gitlab-org/gitlab-environment-toolkit). It aims to be a single source of truth covering areas such as design principles, technical implementations, background and more.

Unless specified otherwise, all additions or changes to the Toolkit should align with this document.

[[_TOC_]]

## What is the GitLab Environment Toolkit?

The GitLab Environment Toolkit (`GET`) is a collection of opinionated [Terraform](https://www.terraform.io/) and [Ansible](https://www.ansible.com/) scripts to assist with deploying GitLab at scale as per the [Reference Architectures](https://docs.gitlab.com/ee/administration/reference_architectures). It uses the official [Linux package (Omnibus)](https://docs.gitlab.com/omnibus/) or [Helm](https://docs.gitlab.com/charts/) packages.

Created and maintained by the GitLab Quality Engineering Enablement team, the Toolkit supports provisioning and configuring machines and other related infrastructure respectively:

- Support for deploying all Reference Architectures sizes dynamically from 1k to 50k.
- Support for deploying Cloud Native Hybrid variants of the Reference Architectures (AWS & GCP only at this time).
- GCP, AWS and Azure cloud provider support
- Upgrades
- Release and nightly Linux package (Omnibus) builds support
- Advanced search with OpenSearch
- Geo support
- Zero Downtime Upgrades support
- Built in Load Balancing and Monitoring (Prometheus) setup
- SSL / TLS (either direct or via hooks)
- Alternative sources (Cloud Services, Custom Servers) for select components (Load Balancers, PostgreSQL, Redis)
- On Prem Support (Ansible)

### What is it not?

The Toolkit is **not** a replacement for [Linux package (Omnibus)](https://docs.gitlab.com/omnibus/) or [GitLab Charts](https://docs.gitlab.com/charts/). It only provides automation scripts to deploy these packages per their instructions and best practices as documented in the [GitLab product documentation](https://docs.gitlab.com/) and [Reference Architectures](https://docs.gitlab.com/ee/administration/reference_architectures/).

The Toolkit is also **not** a replacement for a skilled GitLab Administrator, IT infrastructure expert, or implementations expert in your organization. It is provided as a convenience to ease the deployment of GitLab at scale, but it must still be reviewed, configured, maintained, and even modified to meet your organization's standards. Users who want a managed solution should consider our other offerings such as [GitLab SaaS](https://docs.gitlab.com/ee/subscriptions/gitlab_com/) or [GitLab Dedicated](https://about.gitlab.com/dedicated/).

The Toolkit does not support deploying every infrastructure design or permutation. It is, by design, opinionated in how it approaches infrastructure, but, it is also given as-is for users to take and adjust accordingly to meet their specific needs as required.

The Toolkit should not add any functionality, except to attempt automation of deployment of GitLab at scale. It also should not establish configuration defaults, or handle tasks that are better suited to be done by the Linux package (Omnibus) or Charts.

All feature requests and issues should be considered against this principle. Quite often requests are better raised against GitLab itself.

## Design Principles

### Focused Design

The Toolkit is designed to be a set of scripts to help deploy a _base_ GitLab environment based on the Reference Architectures and then provide various advanced features and / or hooks that users can opt into based on the requirements, not unlike Linux package (Omnibus) or Helm.

This is very much by design and a core pillar of the Toolkit. Features should only be enabled by default where we're confident it applies to most users and doesn't add additional costs. Failure to do this will cause confusion and complaints. For example a change that may make sense for a SaaS environment doesn't for a Self Managed one.

We also must maintain a high bar for any new features or additions. Provisioning and Configuration tools can get complicated fast, being pulled in _many_ directions quickly and fall into disrepair as the maintenance cost becomes too high. The Toolkit already touches on a [substantial amount of areas](#integrations-list) and every new feature is additional long term maintenance.

Changes should only be considered when directly related to deploying GitLab at scale that can't be done in other existing Tools or Cloud Providers. Additionally, the Toolkit shouldn't be working around or trying to make up for limitations in these other areas due to the high maintenance cost - These should be tackled directly in the dependent area.

All changes must be strictly considered against the above.

### Simplicity

The main design principle for the Toolkit is the most important and informs its design completely - **Simplicity**. Echoing the GitLab value of [Boring solutions](https://about.gitlab.com/handbook/values/#boring-solutions) it's critical that simplicity is considered in all aspects of the Toolkit.

Provisioning and Configuration tools get complicated fast. There are typically many ways a certain action can be automated, many valid, but whatever we pick needs to be simple for both the user and the maintainer as detailed below.

### Opinionation

By the very nature of the fact there are various Cloud Providers with numerous services that all have their own options and permutations the Toolkit has to be opinionated.

Examples such as networking, storage, authentication and more have so many options and as a result choices do need to be made, and conversely we may not be able to support the other choice.

We endeavour to keep opinionation as simple as possible and follow best practices in general, but we can't avoid it in some form, so this must be accepted.

#### User Experience

We strive to keep the user experience as simple as possible. Building full GitLab environments across numerous supported cloud providers results in there being _many_ levers available.

To make the Toolkit useful this needs to be streamlined down into a simple and usable interface that provides options to the user in an initiative way.

This is beholden in part to the tools we're using and their own interfaces but for each we still follow this principle of simplicity where possible.

#### Maintainer Experience

It's critical that all code we add to the Toolkit is simple where possible. Every addition needs to be maintained, and simpler code is easier to read and understand. This is required even more so in a Toolkit like this as there's a wide range of code to review - Terraform, Ansible and Ruby (GitLab) - all with their own quirks and considerations.

We avoid complicated code designs or patterns wherever possible to achieve this principle.

### AHA (Avoid Hasty Abstractions)

Generally we follow the pragmatic principle of [AHA - _Avoid Hasty Abstractions_](https://kentcdodds.com/blog/aha-programming#aha-) over [DRY](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself).

This approach works well for this type of tooling. The Toolkit automates tasks that are generally designed to be done manually, and there may be times when repetition of tasks is required or desirable. Readability and Maintainability are more important than reducing code repetition via complicated abstraction.

Some examples:

- Select GitLab config is the same in GitLab Rails and Sidekiq. Extracting these would require abstracting outside their Roles (breaking the point of Roles) and would become pretty hard to follow and maintain if it continued. It's easier to have a single source of truth for each component for readability and maintenance even if that means select config is the same in each.
- Some generated config files from GitLab need to be shared across component nodes but don't exist until the first node has completed setup. This requires code to be present in each Role to either copy the new file to a shared location or copy an existing one over at the right time to keep everything in sync.

### Use Industry Leading Tools and Avoid Custom Implementations

We use industry leading tools natively for Provisioning and Configuration wherever possible - [Terraform](https://www.terraform.io/) and [Ansible](https://www.ansible.com/). These tools are large, complex and mature it wouldn't be viable to try and replace or augment these.

We avoid custom code/implementations wherever possible as this will add additional maintenance cost.

### Shared Responsibility

The Toolkit follows the [Shared Responsibility Model](https://www.crowdstrike.com/cybersecurity-101/cloud-security/shared-responsibility-model/)).

The principle is that Self Managed is primarily the responsibility of the user. GitLab does have responsibility to ensure that the Toolkit's scripts are following the best practices, where possible, specifically for the GitLab application. Outside that scope, such as with infrastructure, the responsibility is with the user to ensure that the environment meets all their requirements, and be aware of ongoing maintenance costs.

## Technical Implementations

### Integrations List

The Toolkit integrates with many tools and services in an opinionated fashion, along with contending with their own designs:

- Terraform
- Ansible
- GitLab
  - Linux package (Omnibus)
  - Helm
- Cloud Providers - AWS, GCP, Azure (Linux package (Omnibus) Only)
  - VMs
  - Kubernetes (Helm)
  - Disks
  - Networking (IPs, VPCs, Subnets, Gateways, Routing or Firewalls)
  - Services (e.g. RDS)

#### Supported Cloud Providers

The Toolkit primarily supports AWS and GCP as target Cloud Providers, [following the general GitLab guidance](https://docs.gitlab.com/ee/administration/reference_architectures/#recommended-cloud-providers-and-services), but we do also support Azure for Linux package (Omnibus) installs only. We also support On Prem setups for Configuration via Ansible.

We're unable to support or accept any contributions for any additional Cloud Providers directly as this would come with a significant maintenance cost and would require access to them on our end for long term testing.

### Terraform

Our Terraform code follows a simple encapsulation approach through [Terraform Modules](https://www.terraform.io/docs/language/modules/develop/index.html).

There are modules created for each Cloud Provider (due to the numerous differences between them). Infrastructure code that can repeat often is a candidate to be moved into its own module.

The Toolkit uses two modules per cloud provider:

- `instance` - Contains all the code required to deploy a VM suitable for GitLab on the selected Cloud Provider.
- `ref_arch` - An encompassing module - it deploys VMs via the `instance` module along with any other supporting infrastructure such as Kubernetes, networking or object storage. Variables are passed through to other modules/resources.
  - This module is designed to be flexible allowing users to only build what they want. Supporting resources should only be built if their dependent is.

In the future we might consider breaking select code down into more modules for further modularity. Overall the design though is to interface mainly through the relevant `ref_arch` module to give a consistent user experience.

#### Version Support

The latest Terraform version we support is noted [here in the documentation](README.md#requirements).

#### Styling

- Terraform code should follow the [Terraform Style Conventions](https://www.terraform.io/docs/language/syntax/style.html). All code should pass a `terraform fmt` check (automatically checked in CI).
- Terraform code should pass the project's lint checks. We utilize [`tflint`](https://github.com/terraform-linters/tflint) and a customized [rules list](.tflint.hcl).
- Variables should be set in the relevant `variables.tf` file for the module.
- All names in both resources and variables should follow the [Snake Case](https://en.wikipedia.org/wiki/Snake_case) naming convention.

#### Variable Defaults (`null`)

For any variables we add in Terraform for the Providers we use, we use [`null` values](https://developer.hashicorp.com/terraform/language/expressions/types#null) first as a rule.

In Terraform `null` is equivalent to something not being set at all and the Cloud Provider's default is then used instead gracefully. This in turn avoids it being set definitively in Terraform's state and avoids any clashes between Terraform, it's state and the Cloud Provider such as when a user changes a setting or if a Cloud Provider changes a default either in its Terraform Provider or directly on it's service(s).

To put it another way setting a value, even if just a default, on this layer means Terraform expects full ownership of it moving forward and as a general rule this behaviour should only be invoked when necessary.

### Ansible

Our Ansible code follows a simple encapsulation approach primarily through [Ansible Roles](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html) and strong usage of [Variables](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html) and [Templates](https://docs.ansible.com/ansible/latest/user_guide/playbooks_templating.html).

To recap there are five main concepts for Ansible:

- [Inventories](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html) - List of machines that Ansible will run against. Typically, we use [Dynamic Inventories](https://docs.ansible.com/ansible/latest/user_guide/intro_dynamic_inventory.html) in the Toolkit that build the list of machines automatically based on machine labels (set by Terraform).
- [Playbooks](https://docs.ansible.com/ansible/latest/user_guide/playbooks.html) - Effectively our "runners", the playbooks select what machines to run on and what Role to run on them
- [Roles](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html) - The bulk of our code. Roles generally correspond to a GitLab component or a collection of actions and contain all the actions required to set up that component. Some Roles are more specialized in that they run on all nodes regardless or on `localhost` when required.
- [Variables](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html) - Variables are used throughout the code in both execution and file templates for GitLab config. All configurable by the user.
- [Templates](https://docs.ansible.com/ansible/latest/user_guide/playbooks_templating.html) - Templates are also used throughout in both Variable expansion and to configure config files on the target nodes.

Utilizing the above the run flow of our code in Ansible is as follows:

- Inventories list the machines with categories based on the labels they already have applied in our Terraform modules.
- Variables are constructed at runtime, pulling from Inventory, Group and Roles. See the section on [Variables](#variables) for more info.
- Playbooks select nodes based on the above-mentioned labels and run the corresponding Role(s) in the correct order required for GitLab.
- Role(s) run tasks on the selected nodes in order, utilizing the constructed Variables or any specific files they have as required.

Some general implementation rules we follow for Ansible:

- Roles should only be added when there's a clear need for them, and they have a good purpose. This is to prevent code fragmentation that in turn will impact maintainability.
- It's allowed to repeat select tasks or config across Roles following the principle of [AHA](#aha-avoid-hasty-abstractions). Tasks should be viewed as equivalent to function calls.

#### Variables

[Ansible's variable precedence](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html#variable-precedence-where-should-i-put-a-variable) can be hard to work with, especially with an Inventory led variable design like the Toolkit's where the goal is for users to pass in their own (overriding) config for each environment.

Previously the Toolkit was created with a Group Vars led design, this has now changed to Role Defaults to better fit Ansible's default precedence.

For the Toolkit, variables must be placed in one of three places depending on their scope to ensure correct precedence as follows:

- Common Vars Role Defaults (`common_vars/defaults/main.yml`) - For any variables that are to be used in more than one Role. All Roles and Playbooks pull this role in as a dependency for this purpose.
- Specific Role Defaults (`<role_name>/defaults/main.yml`) - For any variables that are used in a single role only.
- Group Defaults (`group_vars/<group_name>.yml`) - For any variables that should be applied for a group of nodes.

#### Version Support

The latest Ansible version we support is noted [here in the documentation](README.md#requirements). We regularly update the version to match the latest maintained versions accordingly.

#### Styling

- Ansible code should pass the project's lint checks. We utilize [`ansible-lint`](https://github.com/ansible-community/ansible-lint) and a customized [rules list](ansible/.ansible-lint).
- Variables follow the [Snake Case](https://en.wikipedia.org/wiki/Snake_case) naming convention. In addition to these variables for components typically should follow the convention of `<component>_*` to allow for easier readability and consistency of variables per component.

### General

#### Releases and Supported GitLab Versions

The following rules apply for Toolkit releases and support between them:

- The Toolkit follows [Semantic Versions](https://semver.org/) where we release Major, Minor and Patch versions via [project releases](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/releases).
- Releases are not tied directly to GitLab versions, we currently support GitLab versions from `14.0` onwards.
- Breaking changes such as minimum supported GitLab version may be changed in Major releases with adequate notice and an upgrade path given to users.
- We aim to support Backwards Compatibility between minor releases. Although some small breaking changes may be added with adequate notice if the need is justified.
- Backwards Compatibility is not guaranteed for in development code on the main branch.

#### Prefer Custom Config for GitLab variables

As a general rule we prefer [Custom Config](docs/environment_advanced.md#custom-config) over encapsulating individual GitLab variables for the following reasons:

- Every variable we encapsulate is one we take on and have to maintain. Over time this will accrue and increase brittleness as variables can change between versions.
- To reduce confusion of what should be set in GET vs GitLab directly.
- To reduce clashes with Custom Config when it's used that can be hard to debug.

In other words we should only be handling variables in GET that are needed strictly to achieve deployment of GitLab at scale to stay lean and reduce maintenance burden. Variables not fitting this description should only be encapsulated when there's a strong enough reason to do so, for example if the variable requires to be set across multiple components.

#### Secrets and Keys

Any Secrets and/or Keys for use with the Toolkit are expressly forbidden to be committed in the repo.

The Toolkit has been designed to allow users to add in these via configuring file paths or environment variables accordingly.

#### User Accounts

We expressly avoid the management of User Accounts in the Toolkit wherever possible. This extends to system accounts provided by the Cloud Providers.

This is due to User Accounts being subject to various considerations in regard to security and auditing depending on the company. The Toolkit requires accounts to be created separately as per the required process and passed in where appropriate.
