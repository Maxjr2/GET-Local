# Nutanix Deployment Guide

This is a single, linear walkthrough for deploying GitLab on Nutanix AHV with this Toolkit, from Prism Central credentials to a running, backed-up environment. It complements — rather than duplicates — [Provisioning with Terraform](environment_provision.md#nutanix), [Preparing the environment](environment_prep.md) and [Configuring with Ansible](environment_configure.md); those pages remain the reference for each individual variable.

> [!warning]
> Nutanix support in this fork is experimental and self-maintained (see [Supported Cloud Providers](../TECHNICAL_DESIGN.md#supported-cloud-providers)). Several steps below are marked as unverified against a live cluster — treat them as a starting point, not a guarantee.

## 1. Prism Central API credentials

The Toolkit's Terraform provider (`nutanix/nutanix`) talks to **Prism Central**, not directly to a Prism Element/cluster.

1. In Prism Central, create a dedicated **service account** (or a regular user reserved for automation) rather than reusing an admin's personal login.
2. Assign it a role with at least:
   - VM: create, update, delete
   - Category: create, update, assign to VM
   - Cluster, Subnet, Image, Storage Container: view
3. Note the Prism Central FQDN/IP (`nutanix_endpoint`), the account's username/password, and the port (default `9440`).

These map directly to the provider block in `examples/1k_nutanix/terraform/main.tf`:

```tf
provider "nutanix" {
  endpoint = var.nutanix_endpoint
  username = var.nutanix_username
  password = var.nutanix_password
  insecure = var.nutanix_insecure
}
```

Set the matching values in `examples/1k_nutanix/terraform/variables.tf` (or export `NUTANIX_ENDPOINT`/`NUTANIX_USERNAME`/`NUTANIX_PASSWORD` as environment variables instead of hardcoding them — preferred for anything beyond a local trial). The provider also supports `api_key` authentication against Prism Central as an alternative to username/password — see the [provider docs](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs) if your organization requires it.

## 2. Prerequisites already in Prism Central

Unlike the AWS/GCP/Azure modules this fork removed, the Nutanix module does **not** create a cluster, subnet, base image, or storage container for you — it expects these to already exist, identified by UUID:

| Variable | What it is | How to find it |
|---|---|---|
| `cluster_uuid` | The target AHV cluster | Prism Central UI (Hardware → Clusters), or `nutanix_clusters` data source |
| `subnet_uuid` | Pre-existing subnet/VLAN the VMs attach to | Prism Central UI (Network & Security → Subnets), or `nutanix_subnets` data source |
| `image_uuid` | Base OS image (e.g. an uploaded Ubuntu 24.04 cloud image) VMs are cloned from | Prism Central UI (Compute & Storage → Images), or `nutanix_images` data source |
| `storage_container_uuid` | Storage container backing boot/data disks | Prism Central UI (Compute & Storage → Storage Containers), or `nutanix_storage_containers` data source |

If you'd rather look these up via Terraform than the UI, a one-off `terraform console` session against a throwaway config with `data "nutanix_clusters" "all" {}` (etc.) will list every UUID.

## 3. Provisioning

```bash
cd examples/1k_nutanix/terraform
terraform init
terraform plan
terraform apply
```

This creates the VMs for the components you've sized in `environment.tf` (see [Configure Module settings](environment_provision.md#configure-module-settings-environmenttf) for the `*_node_count`/`*_size` pattern) and tags them with Nutanix categories (`gitlab_node_prefix`, `gitlab_node_type`, `gitlab_node_level`).

Then run Ansible against the dynamic inventory:

```bash
cd examples/1k_nutanix/ansible
ansible-galaxy collection install nutanix.ncp
ansible-playbook -i inventory playbooks/common.yml
ansible-playbook -i inventory playbooks/gitlab_rails.yml
```

From here, follow [Configuring with Ansible](environment_configure.md) as normal — the playbooks themselves are provider-agnostic and don't know or care that the nodes are on Nutanix.

## 4. Lifecycle

**Scaling up/down:** edit the relevant `*_node_count`/`*_size` variables in `environment.tf` and re-run `terraform apply`. Ansible re-run afterwards picks up newly added nodes via the dynamic inventory.

**Destroying an environment:**

```bash
terraform destroy
```

Order-of-operations caveat: Nutanix category **values** can't be deleted while still attached to a VM. `terraform destroy` handles this automatically by destroying VMs before category values in normal cases, but if a `destroy` is interrupted partway through, a stray category-value-still-in-use error means a VM wasn't actually removed yet — check Prism Central directly rather than assuming the category error is the root cause.

**Upgrades:** GitLab version upgrades are handled entirely by Ansible, independent of the underlying infrastructure — see [Upgrades](environment_upgrades.md). There's nothing Nutanix-specific about the upgrade path.

## 5. Backups

Nutanix has no Terraform-managed backup service equivalent to AWS/GCP's managed database backups (which this fork doesn't use anyway — `gitlab_ref_arch_nutanix` always provisions self-managed Postgres/Redis VMs, same as the on-prem path). Two complementary layers:

1. **GitLab-level backups** (required): configure object-storage-backed backups via [Custom Config](environment_advanced.md#custom-config), the same fallback documented for on-prem — point `gitlab_backup_upload_connection` at any S3-compatible endpoint (Nutanix Objects, MinIO, or an external cloud bucket). This fork does not auto-provision object storage, so the bucket/endpoint must exist before you wire it in.
2. **Infrastructure-level snapshots** (recommended, out of Terraform's scope): configure Prism Central VM or volume-group snapshot/protection-domain schedules directly for the provisioned VMs, as a complement to (not a replacement for) application-level GitLab backups. This is standard Nutanix DR tooling and isn't something this Toolkit manages.

## 6. Optional: GitLab Runners

This is best-effort, less-tested guidance — treat it as a starting point.

### Linux runner

Reuse `gitlab_nutanix_instance` directly for a runner VM:

```tf
module "runner_linux" {
  source = "../../modules/gitlab_nutanix_instance"

  prefix                  = var.prefix
  node_type               = "runner-linux"
  cluster_uuid            = var.cluster_uuid
  subnet_uuid             = var.subnet_uuid
  image_uuid              = var.image_uuid
  storage_container_uuid  = var.storage_container_uuid
  vm_admin_username       = var.vm_admin_username
  ssh_public_key          = file(var.ssh_public_key_file_path)
}
```

Once the VM is up, install and register `gitlab-runner` the standard way (Docker or shell executor):

```bash
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash
sudo apt-get install gitlab-runner
sudo gitlab-runner register --url <external_url> --token <runner-registration-token>
```

### Windows runner

The `nutanix_virtual_machine` resource's `guest_customization_cloud_init_user_data` field used elsewhere in this Toolkit is **Linux-only** (cloud-init). Windows guest customization on Nutanix uses **Sysprep** instead (`guest_customization_sysprep` on the same resource), which is a materially different flow — unattended-answer-file based, not a cloud-init script.

There's no `gitlab_nutanix_windows_instance` module in this fork — building a full parallel Windows instance module was out of scope for this pass, so provisioning the VM itself is a manual step:

1. Create a Windows Server VM in Prism Central (manually, or via `nutanix_virtual_machine` with a Windows image and `guest_customization_sysprep` instead of the cloud-init field) with an administrator account and networking reachable from your control node.
2. Enable WinRM (for Ansible) or just RDP in if you're setting it up by hand — this Toolkit's Ansible roles don't cover Windows targets, so this step is entirely outside the playbooks.
3. Install GitLab Runner for Windows and register it:

```powershell
New-Item -ItemType Directory -Path "C:\GitLab-Runner" -Force
Invoke-WebRequest -Uri "https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-windows-amd64.exe" -OutFile "C:\GitLab-Runner\gitlab-runner.exe"
cd C:\GitLab-Runner
.\gitlab-runner.exe install
.\gitlab-runner.exe start
.\gitlab-runner.exe register --url <external_url> --token <runner-registration-token>
```

If you end up building this out further (a real Windows-capable Terraform module, Sysprep-based bootstrapping, WinRM-based Ansible config), that's a natural follow-up contribution to this fork rather than something covered here.
