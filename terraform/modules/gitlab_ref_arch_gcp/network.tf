locals {
  create_network = var.create_network

  # Select vpc \ subnet ids if created or existing. If neither assume defaults
  vpc_name    = local.create_network ? google_compute_network.gitlab_vpc[0].name : var.vpc_name
  subnet_name = local.create_network ? google_compute_subnetwork.gitlab_vpc_subnet[0].name : var.subnet_name
}

# Get full VPC details
data "google_compute_network" "gitlab_network" {
  name = local.vpc_name
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
  ip_cidr_range            = var.subnet_cidr
  network                  = google_compute_network.gitlab_vpc[0].name
  private_ip_google_access = true
}

# External IPs
## Setup Router and NAT when not using external IPs for internet access
resource "google_compute_router" "router" {
  count   = var.setup_external_ips ? 0 : 1
  name    = "${var.prefix}-router"
  network = local.vpc_name
}

resource "google_compute_router_nat" "nat" {
  count  = var.setup_external_ips ? 0 : 1
  name   = "${var.prefix}-nat"
  router = google_compute_router.router[0].name

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# Private Service Access
resource "google_compute_global_address" "gitlab_private_service_ip_range" {
  count = var.cloud_sql_postgres_machine_tier != "" ? 1 : 0

  name          = "${var.prefix}-private-service-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = local.create_network ? google_compute_network.gitlab_vpc[0].id : data.google_compute_network.gitlab_network.id
}

resource "google_service_networking_connection" "gitlab_private_service_access" {
  count = var.cloud_sql_postgres_machine_tier != "" ? 1 : 0

  network                 = local.create_network ? google_compute_network.gitlab_vpc[0].id : data.google_compute_network.gitlab_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.gitlab_private_service_ip_range[0].name]
}
