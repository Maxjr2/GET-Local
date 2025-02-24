locals {
  create_network   = var.create_network
  existing_network = var.vpc_name != "default"

  # Select vpc \ subnet ids if created or existing. If neither assume defaults
  vpc_name    = local.create_network ? google_compute_network.gitlab_vpc[0].name : var.vpc_name
  subnet_name = local.create_network ? google_compute_subnetwork.gitlab_vpc_subnet[0].name : var.subnet_name
}

# Get full VPC and Subnet details for Default / Existing networks
data "google_compute_network" "gitlab_network" {
  count = !local.create_network ? 1 : 0

  name = local.vpc_name
}

data "google_compute_subnetwork" "gitlab_subnet" {
  count = !local.create_network ? 1 : 0

  name = local.subnet_name
}

# Created Network
## Create new network stack
resource "google_compute_network" "gitlab_vpc" {
  count = local.create_network ? 1 : 0

  name                    = "${var.prefix}-vpc"
  auto_create_subnetworks = false
}
resource "google_compute_subnetwork" "gitlab_vpc_subnet" {
  count = local.create_network ? 1 : 0

  name                     = "${var.prefix}-subnet"
  ip_cidr_range            = var.subnet_cidr != null ? var.subnet_cidr : var.create_network_subnet_cidr_block
  network                  = google_compute_network.gitlab_vpc[0].self_link
  private_ip_google_access = true
}
resource "google_compute_network_peering" "gitlab_vpc_peer" {
  count = local.create_network && var.create_network_peer != null ? 1 : 0

  name                                = "${var.prefix}-peer"
  network                             = google_compute_network.gitlab_vpc[0].self_link
  peer_network                        = var.create_network_peer
  import_subnet_routes_with_public_ip = true
}

# External IPs
## Setup Router and NAT when not using external IPs for internet access on VMs or GKE
resource "google_compute_router" "router" {
  count   = var.setup_external_ips == false || var.gke_enable_private_nodes == true ? 1 : 0
  name    = "${var.prefix}-router"
  network = local.create_network ? google_compute_network.gitlab_vpc[0].self_link : data.google_compute_network.gitlab_network[0].self_link
}

resource "google_compute_router_nat" "nat" {
  count  = var.setup_external_ips == false || var.gke_enable_private_nodes == true ? 1 : 0
  name   = "${var.prefix}-nat"
  router = google_compute_router.router[0].name

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# Private Service Access (Cloud SQL)
## Create only if a Cloud SQL (non-replica) instance is to be provided unless outright disabled.
## Can only be configured once on the target VPC and option required for Default / Existing network cases where already set up.
locals {
  setup_private_services_access = var.setup_private_services_access && var.cloud_sql_postgres_machine_tier != "" && var.cloud_sql_postgres_master_instance_name == null
}

resource "google_compute_global_address" "gitlab_private_service_ip_range" {
  count = local.setup_private_services_access ? 1 : 0

  name          = "${var.prefix}-private-service-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = local.create_network ? google_compute_network.gitlab_vpc[0].self_link : data.google_compute_network.gitlab_network[0].self_link
}

resource "google_service_networking_connection" "gitlab_private_service_access" {
  count = local.setup_private_services_access ? 1 : 0

  network                 = local.create_network ? google_compute_network.gitlab_vpc[0].self_link : data.google_compute_network.gitlab_network[0].self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.gitlab_private_service_ip_range[0].name]
  update_on_creation_fail = true # https://github.com/hashicorp/terraform-provider-google/issues/16697

  # Ensures Terraform is able to remove this cleanly
  # https://github.com/hashicorp/terraform-provider-google/issues/16275
  deletion_policy = "ABANDON"
}

output "network" {
  value = {
    "vpc_name"              = local.vpc_name
    "vpc_id"                = local.create_network ? google_compute_network.gitlab_vpc[0].id : data.google_compute_network.gitlab_network[0].id
    "vpc_self_link"         = local.create_network ? google_compute_network.gitlab_vpc[0].self_link : data.google_compute_network.gitlab_network[0].self_link
    "vpc_subnet_name"       = local.subnet_name
    "vpc_subnet_id"         = local.create_network ? google_compute_subnetwork.gitlab_vpc_subnet[0].id : data.google_compute_subnetwork.gitlab_subnet[0].id
    "vpc_subnet_self_link"  = local.create_network ? google_compute_subnetwork.gitlab_vpc_subnet[0].self_link : data.google_compute_subnetwork.gitlab_subnet[0].self_link
    "vpc_subnet_cidr_block" = local.create_network ? google_compute_subnetwork.gitlab_vpc_subnet[0].ip_cidr_range : data.google_compute_subnetwork.gitlab_subnet[0].ip_cidr_range
  }
}
