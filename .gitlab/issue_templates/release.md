<!--
# README first!

This template covers all of the steps required to do a release of the GitLab Environment Toolkit. Issues should only be raised with this template by a GET maintainer who is about to do a release.
-->

## Release Steps

### Prep

- [ ] Confirm no further major MRs are incoming

### Dependency Updates

- [ ] Update Ansible host Python requirements
  - Build and run this [Docker image](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/Dockerfile.python_pkgs_host) to generate the latest list
  - Update [requirements.txt](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/ansible/requirements/requirements.txt)
- [ ] Update Ansible [target host Python requirements](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/ansible/roles/common/defaults/main.yml#L16) (**Optional**)
  - **Note:** Updates require testing on all supported OS versions
  - Build and run this [Docker image](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/Dockerfile.python_pkgs_target) for each OS
- [ ] Update Ansible Roles (**Optional**)
  - Update roles only (not collections, which are minimum pinned to avoid conflicts with the Ansible package)
  - When performing major version bumps, verify functionality on both new and existing environments
  - Roles to update:
    - [ ] `geerlingguy.node_exporter`
    - [ ] `geerlingguy.docker`
- [ ] Update minimum supported GitLab version (only applicable for preparations to GitLab major releases)
  - Update minimum supported GitLab version to align with [GitLab's policy](https://about.gitlab.com/support/statement-of-support/#version-support) of supporting the current major version plus the previous two major versions at [`README.md`](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/README.md?plain=1#L45)
  - Update GET version to GitLab version compatibility table at [`docs/environment_upgrades.md`](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/docs/environment_upgrades.md#toolkit-upgrade-paths-and-stops)

### Third-Party Component Updates (**Optional**)

Update at least annually or when security fixes are available. All updates require testing before release.

- [ ] HAProxy - Set to [latest **LTS** version](https://www.haproxy.org/#latest-versions) in [role defaults](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/ansible/roles/haproxy/defaults/main.yml) (`haproxy_version`)
- [ ] OpenSearch - Set to latest `2.x` version in [role defaults](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/ansible/roles/opensearch/defaults/main.yml) (`opensearch_version`)
- [ ] Node Exporter - Set `node_exporter_version` to the [latest version](https://github.com/prometheus/node_exporter/releases) in `group_vars/all.yml`
- [ ] Kube Prometheus Stack Operator - Set to latest app version in [chart defaults](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/ansible/roles/gitlab_charts/defaults/main.yml) (`kube_prometheus_stack_charts_app_version`)
- [ ] Consul Operator - Set app version to match [Linux package default](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/config/software/consul.rb?ref_type=heads#L21) if newer in [chart defaults](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/ansible/roles/gitlab_charts/defaults/main.yml) (`consul_charts_app_version`)
- [ ] cert-manager - Set to latest `1.x` version in [chart defaults](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/ansible/roles/gitlab_charts/defaults/main.yml) for GitLab Operator installs (`gitlab_operator_cert_manager_version`)

### Terraform Smoke Tests (Major / Minor Releases)

Complete the following tests to ensure there's no unexpected data loss when upgrading from the last release:

- [ ] GCP Omnibus Upgrade
- [ ] GCP Cloud Native Hybrid Upgrade
- [ ] AWS Omnibus Upgrade
- [ ] AWS Cloud Native Hybrid Upgrade
- [ ] Azure Omnibus Upgrade (Only if Azure Terraform changes have been made)

If there has been any specific changes in Terraform relating to optional features they should be tested as well - For example Data Disks or Networking. This can be done as part of the above testing or done separately.

### Backport Process (if applicable)

- [ ] [Create](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/branches/new) `support/<GET_major_minor_x>` branch from GET tag
  - Example: For patch release `3.4.3`, create `support/3.4.x`
  - **Note:** Branch must follow this naming convention to be protected
- [ ] Create MR to update GET version strings in repository
- [ ] Create MR targeting `support/<GET_major_minor_x>` with:
  - Cherry-picked commits for backporting
  - Cherry-picked commit for updated GET version

### Release

- [ ] Update version strings in repository
  - [ ] [`ansible/galaxy.yml`](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/ansible/galaxy.yml#L3)
- [ ] Confirm milestone exists
  - A milestone should typically already exist with all Issues and MRs attached
  - For patch releases, update cherry-picked Issues and MRs to point to the new milestone
- [ ] Create release notes
  - Follow similar style as previous releases
  - Reference [commit history](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/commits/main?ref_type=heads) to collect all changes since last release
  - Format: Major items → Minor items → Upgrade notes/Breaking changes
  - Credit authors where appropriate
- [ ] Create the release
  - [ ] Select to create a new _lightweight_ tag on the release page (no specific notes)
  - [ ] Add formatted release notes:
    - Format: Major items → Minor items → Upgrade notes/Breaking changes
    - Note any [Terraform or Ansible dependency](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/docs/environment_upgrades.md#terraform-and-ansible-dependency-upgrades) updates in the Upgrade Notes section
    - Credit authors where appropriate
    - Link to Docker and Terraform registries (same links as previous releases)
- [ ] Announce release in Slack channels:
  - `#gitlab-environment-toolkit`
  - `#infrastructure_platforms`
  - `#g_dedicated_team`
  - `#support_self-managed`

/label ~"type::maintenance" ~"maintenance::release"
/label ~"group::framework"
/cc @gitlab-org/software-delivery/get-maintainers
