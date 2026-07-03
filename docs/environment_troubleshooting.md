# Troubleshooting

- [GitLab Environment Toolkit - Quick Start Guide](environment_quick_start_guide.md)
- [GitLab Environment Toolkit - Preparing the environment](environment_prep.md)
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
- [**GitLab Environment Toolkit - Troubleshooting**](environment_troubleshooting.md)

On this page you'll find troubleshooting guidance for various areas when using the GitLab Environment Toolkit.

[TOC]

## Troubleshooting

The Toolkit has been designed to deploy GitLab following the same steps as Omnibus.

When working with the Toolkit, you might encounter some of the following issues.

1. Check your config - The most common issues seen with the Toolkit are Terraform or Ansible misconfiguration. In below sections some of the most common misconfigurations are called out and these should be checked first.
1. Check if Omnibus is the root cause of the issue - If the Toolkit configuration looks correct then check if there is an error being thrown by Omnibus. This may be the case if the error is occurring in the `reconfigure` step. If that's the case you should connect to the Omnibus VM and examine the logs, just as you would a standard deployment, for further info.
1. Raise an issue - If the above checks out and none of the below specific scenarios apply then that suggests it's a Toolkit issue. In that case, reach out via a support ticket or issue on this tracker for further help.

## Terraform

### Object Storage Bucket name clashes

Object Storage bucket names have various limitations. One key limitation is that names need to be globally unique. As such, depending on the `prefix` or `object_storage_prefix` you have set the generated bucket names may clash with others globally, and you may see an error saying the buckets already exists. If this occurs, change either of the settings to chose different names for the buckets to workaround.

## Ansible

### Omnibus Reconfigure Errors

On Omnibus environments the Toolkit will be deploying [Omnibus GitLab](https://docs.gitlab.com/omnibus/). The main part of that process is reconfigure (`gitlab-ctl reconfigure`), where Omnibus will set up the configured components. The reconfigure process can be doing a lot and, at times, you may see error(s) being thrown. You may also see Omnibus hang in some cases that in turn will cause Ansible to hang.

Debugging these errors would be the same as if you were setting up Omnibus directly, such as accessing the nodes directly and [examining the logs](https://docs.gitlab.com/omnibus/settings/logs.html). There is notable documentation available on troubleshooting Omnibus issues [here](https://docs.gitlab.com/omnibus/troubleshooting.html).

### Ansible Install Failure: `No matching distribution found`

Ansible releases have a Python version requirement. As such, with new releases can come a requirement on a newer version of Python accordingly.

If the version of Python installed on the control node is too old for the Ansible release, you will see the following error thrown by `pip`:

```sh
ERROR: No matching distribution found for ansible==10.0.0
```

When this occurs you should upgrade your Python version accordingly. The minimum required version is [noted in the documentation](environment_configure.md#1-install-ansible).

### Ansible Install Failure: `Could not find a version that satisfies the requirement`

[Ansible packages can be sometimes be removed by the project's maintainers from the Python Package Index (PyPI) for reasons such as storage](https://forum.ansible.com/t/saving-space-on-pypi/10878/13).

When this happens the following error will be thrown by `pip` when trying to find that version:

```sh
Could not find a version that satisfies the requirement ansible==10.0.0
```

If you are seeing this error, the version will need to be adjusted to one that is available by checking the list on the [PyPI website](https://pypi.org/project/ansible/#history).

### Ansible unable to parse Inventory

You may see an error appear when running Ansible that it couldn't parse the passed Inventory source, for example `Failed to parse environments/<env_name>/files as an inventory source`. This error can be vague unfortunately and it's sometimes not clear what specifically has been missed for the provider plugin.

Some common causes are as follows:

- When the wrong path to the Inventory folder or a path to only the Inventory file and not its folder is given.
- If the inventory folder contains extra files that should be stored in a different location e.g. [custom config files](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/docs/environment_advanced.md#custom-config).
- If there's a misconfiguration or YAML formatting error in the Inventory files.
- If the wrong Inventory file naming format is used. Expected format for Nutanix is `*.nutanix.yml`.
- Missing credentials - This will show with the additional error line `Failed to parse <path>/<configuration>.yml with auto plugin`. This will be generated if the `pc_username`/`pc_password` fields (or equivalent environment variables) haven't been set correctly - see [Configure Authentication (Nutanix)](environment_configure.md#configure-authentication-nutanix).

### Ansible can't find any hosts

Nutanix and Custom Server (on-prem) environments use a [Static Inventory](environment_advanced.md#custom-servers-on-prem), so hosts are defined explicitly rather than being discovered dynamically. If your Ansible
scripts are unable to find any matching hosts, check that `prefix` is
set properly across all YAML files, and that the group names/structure in the Static Inventory file are correct. For example, for the 10K Nutanix
example, check:

1. `all.vars.prefix` in `vars.yml`
1. `category_value` in `10k.nutanix.yml`

Also check that your Prism Central access credentials are correctly specified
in the environment. You can use `ansible-inventory` to see which
hosts Ansible has found:

```shell
ansible-inventory -i environments/10k/inventory --graph
```

Sample output:

```plaintext
@all:
  |--@nutanix:
  |  |--mytest-consul-1
  |  |--mytest-consul-2
  |  |--mytest-consul-3
  |  |--mytest-gitaly-1
  |  |--mytest-gitlab-nfs-1
  |  |--mytest-monitor-1
  |  |--mytest-praefect-1
  |--@consul:
  |  |--mytest-consul-1
  |  |--mytest-consul-2
  |  |--mytest-consul-3
  |--@gitaly:
  |  |--mytest-gitaly-1
  |--@gitaly_primary:
  |  |--mytest-gitaly-1
  |--@gitlab:
  |--@gitlab_nfs:
  |  |--mytest-gitlab-nfs-1
  |--@global:
  |--@monitor:
  |  |--mytest-monitor-1
  |--@praefect:
  |  |--mytest-praefect-1
  |--@praefect_primary:
  |  |--mytest-praefect-1
  |--@ungrouped:
```

You can also troubleshoot Ansible issues by using `ansible-inventory` to
show the configuration for specific hosts from. For example, suppose in
the above example you wanted to display what Ansible has loaded for
`mytest-gitaly-1`. The following command would show JSON data for many
of the variables used in the playbooks:

```shell
ansible-inventory -i environments/10k/inventory --graph --host mytest-gitaly-1
```

### OS Package repository issues

A subtle issue that can occur is when the OS repository script the [Toolkit is configured to use](environment_configure.md#repository) for setting up the repo is not correct for the target OS. When this occurs you may see a message such as `Package gitlab-ee cannot be found`.

Examples of this include the GitLab repo not having packages for the specific OS version or CPU architecture type.

To fix this the "bad" repository should be removed as per the OS instructions and then the correct one configured via Ansible in a subsequent run.

### GitLab GPG key not updated after key rotation

After a GitLab GPG key rotation or expiry extension, you may see GPG check errors when running package operations on RHEL or legacy Debian-based systems.

This is due to previous versions of the Toolkit relying on Ansible's `rpm_key` and `apt_key` modules which, by design, only check for the presence of a key by ID — they do not compare key contents. This means that if a key is rotated or its expiry extended (keeping the same key ID), the modules consider the key already present and skip re-import.

For manual remediation steps by OS, see the [Linux package signatures documentation](https://docs.gitlab.com/omnibus/update/package_signatures/).

### Postgres Upgrade Error: `PostgreSQL did not respond before service checks were exhausted`

The following error can show when running the Toolkit on PostgreSQL nodes:

```sh
ruby_block[wait for postgresql to start] (patroni::enable line 105) had an error: RuntimeError: PostgreSQL did not respond before service checks were exhausted
```

This is due to a [rare application issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/work_items/5969) where the specific Secondary Postgres server has become corrupted and unable to sync replication with the Primary server, causing it to enter a restart loop.

If you examine the specific Postgres server's logs (`/var/log/gitlab/patroni/current`) you'll likely see the real error as follows:

```sh
LOG:  invalid resource manager ID in primary checkpoint record
PANIC:  could not locate a valid checkpoint record
/var/opt/gitlab/postgresql:5432 - rejecting connections
FATAL:  the database system is starting up
/var/opt/gitlab/postgresql:5432 - rejecting connections
FATAL:  the database system is starting up
LOG:  startup process (PID 3711) was terminated by signal 6: Aborted
LOG:  aborting startup due to startup process failure
```

To fix this you need to reset the WAL log on the specific server as follows:

```sh
# Stop the Patroni service
gitlab-ctl stop patroni

# Run the following command as the gitlab-psql user via sudo su
sudo su - gitlab-psql -c '/opt/gitlab/embedded/bin/pg_resetwal -f /var/opt/gitlab/postgresql/data'
```

> [!caution]
> This command deletes the current record and as such may lead to data loss. It should only be run on the specific server with the corrupted log.

This wipes the records from the specific server and will unblock it to start replicating again. This should **only** be run on the specific Secondary server that is failing and no others as this would lead to data loss.

### External Postgres Connection Error from Ansible: `unable to connect to database: FATAL: <reason>`

As a convenience, the Toolkit attempts to prep any external database it's given for GitLab such as creating users or enabling extensions. It does this directly before setting up GitLab.

There may be times though, depending on the database setup, where Ansible is unable to connect to the database such as when mutual 2-way SSL authentication is enabled due to limitations.

When this is the case external database preparation (creating users, enabling extensions, etc.) needs to be completed manually before running Ansible.

### Rails or Sidekiq fails to deploy due to Redis `URI::InvalidURIError` error

As part of the Omnibus reconfigure step you may see the following error occurring for Rails or Sidekiq nodes:

```sh
URI::InvalidURIError: bad URI(is not URI?): "redis://<password>@gitlab-redis-cache"
```

This can happen as the password for the Redis cluster is required to be part of the URL for clients. As a result, if the password contains forbidden characters for http URLs the above error may show.

To fix, adjust the Redis password to not contain any URL forbidden characters and rerun Ansible.

### Worker thread was found in dead state

[This is due to an issue with certain Python plugins](https://github.com/ansible/ansible/issues/32554#issuecomment-642896861) on your system. You can work around this by running `export no_proxy="*"` before running the `ansible-playbook` commands.

### Unable to execute ssh command line on a controller due to: [Errno 24] Too many open files

[This can occur for some people if Ansible is trying run multiple tasks at once](https://github.com/ansible/ansible/issues/12259). The safest way to resolve this is to lower the `forks` setting in your `ansible.cfg` file to `20`. The `ansible.cfg` file can be found at `./ansible/ansible.cfg` within your toolkit checkout.

### Let's Encrypt `acme.sh` renewal failures on HAProxy Linux Package nodes

A bug was introduced with [GitLab Environment Toolkit `3.1.0`](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/releases/3.1.0) with the switch to `acme.sh` as the tool to generate Let's Encrypt SSL certificates on HAProxy Linux Package nodes that prevented automatic renewals from happening due to a permissions issue.

This was [addressed](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/merge_requests/1247) in [`3.2.0`](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/releases/3.2.0) and renewals should work again after running Ansible on this version or later.

If you're unable to upgrade or for some reason the certs still have not renewed, this can be manually worked around by running the following command on the HAProxy External node:

```sh
/opt/acme.sh/acme.sh --renew --domain <external_host>
```

### HAProxy fails to restart after changing the External URL with Let's Encrypt

If the `external_url` of an existing environment is changed when using the built-in Let's Encrypt integration, manual cleanup of the old domain's certificates on the HAProxy nodes is required. 

If HAProxy fails to start after an `external_url` change, it is typically because `acme.sh` does not automatically prune old domains from its renewal list or remove the old files. Since the Toolkit configures HAProxy to load the entire `/opt/haproxy/ssl/` directory for SNI routing, any orphaned certificates left behind will cause HAProxy to fail on restart. To prevent destructive operations during routine updates, the Toolkit does not automatically delete these files.

To fix the deployment and clean up the old domain safely, the provided maintenance playbook can be used by passing the old domain via the `old_domain` variable:

```bash
ansible-playbook -i environments/<env>/inventory playbooks/maintenance/acme_sh_remove_domain.yml -e old_domain=<old_domain>
```

Alternatively, the cleanup commands can be run manually via Ansible ad-hoc commands:

```bash
ansible haproxy_external -i environments/<env>/inventory -b -m shell -a "/opt/acme.sh/acme.sh --remove -d <old_domain> && rm -rf /opt/haproxy/ssl/<old_domain>.pem* /opt/acme.sh/<old_domain> /opt/acme.sh/<old_domain>_ecc && docker restart haproxy"
```

### OS Deprecation Failures

The following errors presented on systems where upstream deprecations has occurred:

- **Python error:** `module 'tarfile' has no attribute 'data_filter'`
  - **Cause:** Occurs on RHEL 8 systems due to a specific security update in the `python-libs` package
  - **Resolution:** Update the `python-libs` package on the target system

- **Ansible error:** `SyntaxError: future feature annotations is not defined`
  - **Cause:** Occurs on RHEL 8 systems when using Ansible 10.0+ (`ansible-core` 2.17+) due to [Ansible removing support for Python 3.6](https://github.com/ansible-collections/news-for-maintainers/issues/54)
  - **Resolution:** Use Ansible 9.x or earlier (`ansible-core` 2.16 or earlier), or upgrade target OS to RHEL 9+

- **Ansible error:** `Module not found: rpm` or related package manager errors
  - **Cause:** Occurs on Amazon Linux 2 systems when using Ansible 10.0+ (`ansible-core` 2.17+) due to [Ansible removing support for the `yum` package manager](https://github.com/ansible/ansible/issues/83428#issuecomment-2161516707)
  - **Resolution:** Use Ansible 9.x or earlier (`ansible-core` 2.16 or earlier), or upgrade target OS to Amazon Linux 2023+

- **Ansible error:** `Ansible requires Python 3.9 or newer on the target`
  - **Cause:** Occurs on Ubuntu 20.04 systems when using Ansible 13.0+ (`ansible-core` 2.20+) which requires Python 3.9+ and has dropped Python 3.8 support
  - **Resolution:** Use Ansible 12.x or earlier (`ansible-core` 2.19 or earlier), or upgrade target OS to Ubuntu 22.04+

For comprehensive information on target OS compatibility and required Ansible versions, see [Target Node Operating System Support](environment_configure.md#target-node-operating-system-support).

## GitLab

## Database migration failures

Database migrations can fail during initial setup or upgrades on any GitLab environment, resulting in incomplete or missing data. Common issues include missing users, `undefined method` errors, or features not working as expected.

**First steps:**

Check the [status of database migrations](https://docs.gitlab.com/ee/administration/raketasks/maintenance.html#display-status-of-database-migrations). All migrations should show as `up`. If any have a `down` status, follow the [Run incomplete database migrations](https://docs.gitlab.com/ee/administration/raketasks/maintenance.html#run-incomplete-database-migrations) guidance. [Database migration logs](https://docs.gitlab.com/ee/administration/logs/#migrationslog) can help identify what failed.

If migrations complete successfully but issues persist, see the specific scenarios below.

### `root` user missing after setup

The root admin user may be missing when migrations fail during initial setup.

After confirming all migrations have completed successfully, create the root user manually via Rails console. See [Create users through the Rails console](https://docs.gitlab.com/user/profile/account/create_accounts/#create-users-through-the-rails-console) for instructions (set `admin: true` to create the root admin user).

Alternatively, rebuild the environment from a fresh installation.

### `undefined method` errors

Missing database data can cause `undefined method` errors during Ansible task execution:

```sh
undefined method `diff_max_files' for #<ApplicationSetting:0x00007f99dff105d8>
Did you mean?  diff_max_patch_bytes
```

These errors typically indicate database schema or seed data issues. If migrations show as complete but these errors persist, contact GitLab Support for assistance.

### `422` Error on Login due to Redis misconfiguration

If you are seeing a 422 error when trying to log into the deployed GitLab environment. This is a general HTTP error code and can mean many things but one potential reason for this is Redis setup misconfiguration.

In particular, this can happen when you have configured a separated Redis setup, as recommended for the [10k Reference Architecture](https://docs.gitlab.com/ee/administration/reference_architectures/10k_users.html) and up, but not set up both the Redis Persistent and Cache clusters accordingly, i.e. only one of these have been set. The Toolkit requires either a combined single Redis cluster or both Redis Persistent and Cache clusters to be configured. Anything other that this may result in this error.

If this issue is occurring, switch to either a combined Redis or separated Redis clusters as recommended and go through set up again. Note that after setup you may also need to clear browser caches to clear out the old issue on clients.

### `OpenSSL::Cipher::CipherError` error after running GET playbook on a restored environment with transferred secrets 

The playbook may have overwritten the secrets copied from the source environment. Ensure you have correctly transferred the secrets from the
source environment to the restored target environment using one of the methods described [here](environment_post_considerations.md#restores). 

## Other

### macOS: Python package install failure `fatal error: 'openssl/opensslv.h' file not found`

For macOS users, installation of Python packages via `pip3 install` may fail with an error:

```plaintext
fatal error: 'openssl/opensslv.h' file not found
```

You may first need to set up compiler flags to point to OpenSSL:

```shell
brew install openssl@1.1 rust
export LDFLAGS="-L$(brew --prefix openssl@1.1)/lib"
export CFLAGS="-I$(brew --prefix openssl@1.1)/include"
```

For more details, see:

1. [Documentation on installing the cryptography Python package](https://cryptography.io/en/latest/installation/#building-cryptography-on-macos)
1. [Discussion in GitHub issue](https://github.com/pyca/cryptography/issues/3489#issuecomment-318070912)

### Postgres' logs are missing (Omnibus HA)

Postgres processes in Omnibus when configured are run under Patroni processes, which manages Postgres replication and failover for HA.

As a result Postgres logs are typically found under `/var/log/gitlab/patroni` and not `/var/log/gitlab/postgres`.

### HAProxy / OpenSearch logs are missing

HAProxy / OpenSearch are run as Docker Containers. You can view their logs via the standard [Docker command](https://docs.docker.com/engine/reference/commandline/logs/).
