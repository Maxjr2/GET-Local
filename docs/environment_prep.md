# Preparing the environment

- [GitLab Environment Toolkit - Quick Start Guide](environment_quick_start_guide.md)
- [**GitLab Environment Toolkit - Preparing the environment**](environment_prep.md)
- [GitLab Environment Toolkit - Provisioning the environment with Terraform](environment_provision.md)
- [GitLab Environment Toolkit - Configuring the environment with Ansible](environment_configure.md)
- [GitLab Environment Toolkit - Advanced - Custom Config / Tasks / Files, Data Disks, Advanced Search, Container Registry and more](environment_advanced.md)
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

Preparation is required prior to building out an environment depending on where you intend to host it. This fork of the Toolkit supports two deployment targets: **Nutanix AHV** (via Terraform) and **on-prem/custom servers** (configured directly via Ansible static inventory, with no Terraform provisioning step). These docs assume working knowledge of whichever target you select.

This page starts off with general guidance around fundamentals but then will split off into the steps for Nutanix. If you're using static inventory against existing/on-prem servers, you can skip the Nutanix-specific section below and proceed straight to [Configuring the environment with Ansible](environment_configure.md).

[TOC]

## Overview

Before you begin preparing your environment there are several fundamentals that are worth calling out regardless of deployment target.

After reading through these proceed to the Nutanix section below (skip it if you're using static inventory).

### Authentication

Each of the tools in this Toolkit, and even GitLab itself, all require authentication to be configured for the following:

- Direct authentication with Nutanix Prism Central (Terraform, Ansible)
- SSH authentication with machines (Ansible)

Authentication for Nutanix is detailed in the section below. For on-prem/static inventory targets, only SSH authentication with the machines is required.

### Terraform State

When using Terraform, one important caveat is preparing its [State](https://developer.hashicorp.com/terraform/language/state) file. Terraform's State is integral to how it works. For every action it will store and update the state with the full environment status each time. It then refers to this for subsequent actions to ensure the environment is always exactly as configured.

[Terraform has numerous possible backends](https://developer.hashicorp.com/terraform/language/state/remote-state-data) where the state can be stored. As a general guidance we recommend a remote backend that can be shared between applicable users, such as [GitLab's own managed Terraform State backend](https://docs.gitlab.com/ee/user/infrastructure/iac/terraform_state.html). Whatever backend is chosen the configuration is set in the same location - the environment's `main.tf` file.

> [!important]
> Store Terraform state in a unique location per environment to avoid state clashes between environments.

### Static External IP

Note that Nutanix AHV has no equivalent of a cloud provider's managed static/external IP resource - there's nothing to provision ahead of time here. External access to the environment is instead handled via your existing network/VLAN routing. See the [Nutanix section of Provisioning the environment with Terraform](environment_provision.md#nutanix) for more detail.

## Nutanix

Preparing a Nutanix AHV environment mainly consists of gathering the identifiers of resources that must already exist in Prism Central, since the Toolkit's Terraform module does not create the cluster, subnet, storage container or base OS image itself.

At a high level you'll need:

- Access to a Prism Central endpoint, with a username/password (or other supported credential) that has permissions to create VMs, disks and categories.
- The UUID of the target Nutanix AHV **cluster**.
- The UUID of the pre-existing **subnet**/VLAN the VMs should attach to.
- The UUID of a pre-existing base OS **image** (e.g. an Ubuntu 24.04 cloud image) to clone VMs from.
- The UUID of the **storage container** to use for boot and data disks.
- An SSH key pair to inject into VMs via cloud-init for Ansible access.

For full step-by-step guidance on obtaining these from Prism Central, see [the Nutanix deployment guide](environment_nutanix_deployment_guide.md).

Once you have these details, proceed to the [Nutanix section of Provisioning the environment with Terraform](environment_provision.md#nutanix) to configure them in Terraform.

## Next Steps

After the above steps have been completed you can proceed to [Provisioning the environment with Terraform](environment_provision.md).
