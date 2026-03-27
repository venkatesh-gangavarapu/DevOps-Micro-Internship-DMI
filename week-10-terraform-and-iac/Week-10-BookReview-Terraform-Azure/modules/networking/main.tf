# Resource group containing all project resources.
resource "azurerm_resource_group" "rg" {
  name     = "${var.project}-rg"
  location = var.location

  tags = {
    Name = "${var.project}-rg"
  }
}

# Virtual Network replacing the AWS VPC.
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.project}-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.vpc_cidr_block]

  tags = {
    Name = "${var.project}-vnet"
  }
}

# Public-facing subnet for web tier (zone 1).
resource "azurerm_subnet" "web_subnet_1" {
  name                 = "${var.project}-web-subnet-1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.web_subnet_1_cidr]
}

# Public-facing subnet for web tier (zone 2).
resource "azurerm_subnet" "web_subnet_2" {
  name                 = "${var.project}-web-subnet-2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.web_subnet_2_cidr]
}

# Private subnet for app tier (zone 1).
resource "azurerm_subnet" "app_subnet_1" {
  name                 = "${var.project}-app-subnet-1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.app_subnet_1_cidr]
}

# Private subnet for app tier (zone 2).
resource "azurerm_subnet" "app_subnet_2" {
  name                 = "${var.project}-app-subnet-2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.app_subnet_2_cidr]
}

# Primary database subnet delegated to MySQL Flexible Server.
# No other resource type can be deployed into a delegated subnet.
resource "azurerm_subnet" "db_subnet_1" {
  name                 = "${var.project}-db-subnet-1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.db_subnet_1_cidr]

  delegation {
    name = "mysql-flexible-server-delegation"
    service_delegation {
      name    = "Microsoft.DBforMySQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# Secondary database subnet retained for future use.
resource "azurerm_subnet" "db_subnet_2" {
  name                 = "${var.project}-db-subnet-2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.db_subnet_2_cidr]
}

# Public IP for the NAT Gateway that provides outbound internet access to private subnets.
resource "azurerm_public_ip" "nat_gw_pip" {
  name                = "${var.project}-nat-gw-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Name = "${var.project}-nat-gw-pip"
  }
}

# NAT Gateway enabling outbound internet for private app subnets.
# Replaces the AWS Internet Gateway + NAT Gateway combination used for private subnets.
resource "azurerm_nat_gateway" "nat_gw" {
  name                = "${var.project}-nat-gw"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Standard"

  tags = {
    Name = "${var.project}-nat-gw"
  }
}

resource "azurerm_nat_gateway_public_ip_association" "nat_gw_pip_assoc" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gw.id
  public_ip_address_id = azurerm_public_ip.nat_gw_pip.id
}

# Associate NAT Gateway with app subnets so private VMs can reach internet for updates/installs.
resource "azurerm_subnet_nat_gateway_association" "app_subnet_1_nat" {
  subnet_id      = azurerm_subnet.app_subnet_1.id
  nat_gateway_id = azurerm_nat_gateway.nat_gw.id
}

resource "azurerm_subnet_nat_gateway_association" "app_subnet_2_nat" {
  subnet_id      = azurerm_subnet.app_subnet_2.id
  nat_gateway_id = azurerm_nat_gateway.nat_gw.id
}

# Pre-allocated static public IP for the public Load Balancer.
# Created here instead of the loadbalancer module so the IP address is known before
# VMs are provisioned, allowing it to be injected into user_data scripts without a
# circular dependency (compute needs LB IP → loadbalancer needs compute NIC IDs).
resource "azurerm_public_ip" "public_lb_pip" {
  name                = "${var.project}-public-lb-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Name = "${var.project}-public-lb-pip"
  }
}

# Private DNS zone required by MySQL Flexible Server for VNet integration.
resource "azurerm_private_dns_zone" "mysql" {
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    Name = "${var.project}-mysql-dns-zone"
  }
}

# Link the DNS zone to the VNet so MySQL FQDNs resolve privately within the network.
resource "azurerm_private_dns_zone_virtual_network_link" "mysql_vnet_link" {
  name                  = "${var.project}-mysql-vnet-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.mysql.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false

  tags = {
    Name = "${var.project}-mysql-vnet-link"
  }
}

# Deterministic static private IP for the internal load balancer frontend,
# computed from the app subnet CIDR (10th host address, well above Azure's reserved .1-.3).
locals {
  private_lb_ip = cidrhost(var.app_subnet_1_cidr, 10)
}
