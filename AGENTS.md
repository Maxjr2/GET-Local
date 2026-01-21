# AGENTS.md - GitLab Environment Toolkit

This file provides guidance for AI coding agents working on the GitLab Environment Toolkit (GET).

## Project Overview

The GitLab Environment Toolkit is a collection of opinionated Terraform and Ansible scripts to deploy scaled GitLab environments following the Reference Architectures. It supports GCP, AWS, and Azure cloud providers.

## Build, Lint, and Test Commands

> [!note]
> For comprehensive testing documentation, see [TESTING.md](TESTING.md). This section provides quick reference commands for common tasks.

### Terraform

```bash
# Format check
terraform fmt -check -recursive -diff .

# Lint (run from terraform/modules/)
cd terraform/modules
tflint -c "$PWD/../../.tflint.hcl" --recursive

# Run all tests (from test directory, e.g., terraform/modules/test/mock/aws)
cd terraform/modules/test/mock/aws
terraform init
terraform test

# Run a specific test file
terraform test -filter 10k.tftest.hcl
```

### Ansible

```bash
# Install dependencies first
cd ansible
ansible-galaxy install -r requirements/ansible-galaxy-requirements.yml
pip install jmespath

# Lint
ansible-lint

# Run Molecule tests (from ansible directory)
molecule test --scenario-name single-node-with-haproxy

# Keep infrastructure running for debugging
molecule converge --scenario-name single-node-with-haproxy

# Destroy infrastructure
molecule destroy --scenario-name single-node-with-haproxy
```

### Markdown

```bash
# Lint
markdownlint *.md docs/*.md

# Check external links
markdown-link-check *.md docs/*.md

# Check internal links and fragments
lychee --offline --no-progress --quiet --include-fragments $(find . -type f -name "*.md")
```

### Security Scanning

```bash
# Secret detection (fails on violations)
# Runs automatically in CI

# KICS IaC scanning (fails on violations)
# Runs automatically in CI
```

## Code Style Guidelines

### General Principles

1. **Simplicity First**: Follow the GitLab value of "Boring solutions". Keep code simple and maintainable.
1. **AHA Over DRY**: Avoid Hasty Abstractions. Readability and maintainability are more important than reducing code repetition.
1. **Opinionated by Design**: The toolkit makes specific choices about infrastructure. Not every permutation can be supported.
1. **Native Tools**: Use Terraform and Ansible natively. Avoid custom implementations.

### Terraform

#### Naming Conventions

- **snake_case** for all resources, variables, outputs, and modules
- Variable names should be descriptive and follow pattern: `<component>_<attribute>_<detail>`
- Example: `gitaly_disk_size`, `rds_postgres_instance_type`

#### File Organization

- Separate files per component: `gitaly.tf`, `postgres.tf`, `network.tf`, etc.
- `variables.tf` for all variable definitions
- `main.tf` for provider configuration and core logic
- `outputs.tf` for outputs (if needed)

#### Variable Definitions

```hcl
variable "prefix" {
  description = "Prefix to use on all provisioned resources"
  type        = string
  default     = null

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{2,29}$", var.prefix))
    error_message = "The prefix must be all lowercase alphanumeric characters, between 3 and 30 characters in length."
  }
}
```

#### Module Usage

```hcl
module "gitaly" {
  source = "../gitlab_aws_instance"

  prefix     = var.prefix
  node_type  = "gitaly"
  node_count = var.gitaly_node_count
  
  custom_tags = merge(var.additional_tags, var.custom_tags, var.gitaly_custom_tags)
  
  # Use coalesce for fallback values
  disk_size = coalesce(var.gitaly_disk_size, var.default_disk_size)
}
```

#### Required Versions

- Terraform version: See `.tool-versions` for the required version
- Provider versions should use `~>` for flexibility (e.g., `"~> 7.0"`)

### Ansible

#### File Structure

- Roles in `ansible/roles/<component>/`
- Playbooks in `ansible/playbooks/`
- Group vars in `ansible/playbooks/group_vars/`
- Molecule scenarios in `ansible/molecule/<scenario>/`

#### Task Structure

```yaml
---
- name: Setup GitLab config file
  template:
    src: templates/gitaly.gitlab.rb.j2
    dest: /etc/gitlab/gitlab.rb
  register: result
  retries: 3
  until: result is success
  tags: reconfigure

- name: Configure Custom Config
  block:
    - name: Check if custom config exists
      stat:
        path: "{{ gitaly_custom_config_file }}"
      delegate_to: localhost
      become: false
      register: gitaly_custom_config_file_path
```

#### Naming Conventions

- Task names: Descriptive, action-oriented (e.g., "Setup GitLab config file")
- Variables: Use component prefix (e.g., `gitaly_custom_config_file`)
- Use `snake_case` for all variables and file names

#### Handling Sensitive Data

Always use `no_log: true` when working with secrets, passwords, tokens, or other sensitive information:

```yaml
- name: Read GitLab secrets
  slurp:
    path: "/etc/gitlab/gitlab-secrets.json"
  register: gitlab_secrets_slurp
  no_log: true
  when: gitlab_secrets_file_path.stat.exists

- name: Apply license
  command: gitlab-rails runner "License.add_license(...)"
  no_log: true
```

#### Tags

Common tags: `reconfigure`, `secrets`, `gitlab-secrets`

#### Linting Rules

The project uses custom ansible-lint rules in `.ansible-lint-rules/`. Key rules:

- Line length limits relaxed
- Some risky operations allowed for infrastructure automation
- FQCN (Fully Qualified Collection Names) optional but encouraged

### Markdown Documentation

#### Style Requirements

- First header must be H1
- Use ATX-style headers (`#` not underlines)
- Use dash style for unordered lists (`-` not `*`)
- Use horizontal rules with `---`
- Use fenced code blocks (not indented)
- No trailing spaces (relaxed)
- No line length limits (relaxed)

#### Structure

- Start with project overview
- Include Table of Contents (`[TOC]`)
- Use note blocks: `> [!note]` for callouts
- Link to relevant GitLab documentation
- Include examples for configuration options

## Error Handling

### Terraform

- Use validation blocks for input validation
- Provide clear error messages
- Use `null` as default for optional variables
- Use `coalesce()` for fallback values

### Ansible

- Use `register` to capture task results
- Add `retries` and `until` for potentially flaky operations
- Use `block` for logical grouping
- Set `any_errors_fatal = True` in ansible.cfg (project default)

## Git Workflow

### Branch Labels

- `~"workflow::in dev"` - Work in progress
- `~"workflow::ready for review"` - Ready for maintainer review
- `~"workflow::in review"` - Being reviewed
- `~"breaking change"` - Introduces breaking changes

### Review Process

1. Mention `@gitlab-org/software-delivery/get-maintainers` when ready for review
1. Apply `~"workflow::ready for review"` label
1. Maintainer will add themselves as Reviewer and apply `~"workflow::in review"`
1. Keep MRs small and focused (GitLab's Iteration value)

## Testing Requirements

For comprehensive testing guidance, refer to [TESTING.md](TESTING.md).

### Before Committing

1. Run appropriate linters (terraform fmt, tflint, ansible-lint, markdownlint)
1. Run relevant tests (Terraform tests or Molecule scenarios - see [TESTING.md](TESTING.md))
1. Ensure no secrets are committed

## Important Notes for Agents

1. **Read TECHNICAL_DESIGN.md** before making significant changes
1. **Check existing patterns** in similar components before implementing new features
1. **Test on all relevant cloud providers** if changes affect provisioning
1. **Update documentation** in `docs/` directory when adding features
1. **Consider maintenance burden** - every feature adds long-term maintenance cost
1. **Don't abstract prematurely** - duplicate code is okay if it improves readability
1. **Security first** - never commit secrets, always use secure defaults
1. **Cloud costs matter** - document cost implications of new features
