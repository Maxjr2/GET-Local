terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  peer_connection_id = (
    var.mode == "requester" ?
    one(aws_vpc_peering_connection.gitlab_vpc_peering_requester[*].id) :
    one(aws_vpc_peering_connection_accepter.gitlab_vpc_peering_accepter[*].id)
  )
}

# Route to VPC peer
resource "aws_route" "gitlab_vpc_rt_peering" {
  # Ideally, for_each would be better here, but this causes
  # terraform resolution issues, so falling back to count
  # which doesn't have the same issue
  count = length(var.route_table_ids)

  route_table_id            = var.route_table_ids[count.index]
  destination_cidr_block    = var.peer_vpc_cidr
  vpc_peering_connection_id = local.peer_connection_id
}

# Setup network peering for Geo
resource "aws_vpc_peering_connection" "gitlab_vpc_peering_requester" {
  count = var.mode == "requester" ? 1 : 0

  peer_region = var.peer_region
  peer_vpc_id = var.peer_vpc_id
  vpc_id      = var.vpc_id
  auto_accept = false
}

resource "aws_vpc_peering_connection_accepter" "gitlab_vpc_peering_accepter" {
  count = var.mode == "accepter" ? 1 : 0

  vpc_peering_connection_id = var.peer_connection_id
  auto_accept               = true
}
