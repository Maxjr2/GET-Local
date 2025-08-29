resource "azurerm_virtual_network" "gitlab" {
  name                = "${var.prefix}-default-network"
  address_space       = var.vnet_address_space
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "gitlab" {
  name                 = "${var.prefix}-internal-subnet"
  virtual_network_name = azurerm_virtual_network.gitlab.name
  address_prefixes     = var.subnet_address_ranges
  resource_group_name  = var.resource_group_name
}

# External IPs
## Setup NAT when not using external IPs for internet access
resource "azurerm_public_ip" "nat_gateway_public_ip" {
  count = var.setup_external_ips ? 0 : 1

  name                = "${var.prefix}-nat-gateway-public-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  lifecycle {
    # Ignore changes in the Zones which force recreation of the resource. This
    # avoids accidental deletion of IPs after AzureRM v3.0 upgrade
    # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/3.0-upgrade-guide#resource-azurerm_public_ip
    ignore_changes = [
      zones
    ]
  }
}

resource "azurerm_nat_gateway" "nat_gateway" {
  count = var.setup_external_ips ? 0 : 1

  name                    = "${var.prefix}-nat-gateway"
  location                = var.location
  resource_group_name     = var.resource_group_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = var.nat_gateway_idle_timeout_in_minutes
}

resource "azurerm_nat_gateway_public_ip_association" "nat_gateway" {
  count = var.setup_external_ips ? 0 : 1

  nat_gateway_id       = azurerm_nat_gateway.nat_gateway[0].id
  public_ip_address_id = azurerm_public_ip.nat_gateway_public_ip[0].id
}

resource "azurerm_subnet_nat_gateway_association" "nat_gateway" {
  count = var.setup_external_ips ? 0 : 1

  subnet_id      = azurerm_subnet.gitlab.id
  nat_gateway_id = azurerm_nat_gateway.nat_gateway[0].id
}

output "network" {
  value = {
    "vpc_name"   = azurerm_virtual_network.gitlab.name
    "vpc_subnet" = azurerm_subnet.gitlab.address_prefixes
  }
}
