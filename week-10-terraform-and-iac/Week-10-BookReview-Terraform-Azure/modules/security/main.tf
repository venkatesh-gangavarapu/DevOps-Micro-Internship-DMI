# NSG for web tier subnets.
# Allows HTTP (port 80) and SSH (port 22) from the internet, plus Azure LB health probes.
resource "azurerm_network_security_group" "web_nsg" {
  name                = "${var.project}-web-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "AllowHTTPInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowSSHInbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  # Required for Azure Standard Load Balancer health probes to reach backend VMs.
  security_rule {
    name                       = "AllowAzureLoadBalancerInbound"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  tags = {
    Name = "${var.project}-web-nsg"
  }
}

# NSG for app tier subnets.
# Restricts inbound to port 3001 and SSH from web subnets only.
# A deny-all rule overrides Azure's default AllowVnetInBound to enforce strict isolation.
resource "azurerm_network_security_group" "app_nsg" {
  name                = "${var.project}-app-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "AllowAppPortFromWebSubnet1"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3001"
    source_address_prefix      = var.web_subnet_1_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAppPortFromWebSubnet2"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3001"
    source_address_prefix      = var.web_subnet_2_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowSSHFromWebSubnet1"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.web_subnet_1_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowSSHFromWebSubnet2"
    priority                   = 210
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.web_subnet_2_cidr
    destination_address_prefix = "*"
  }

  # Required for Azure Standard Load Balancer health probes.
  security_rule {
    name                       = "AllowAzureLoadBalancerInbound"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  # Deny all other inbound traffic (overrides Azure default AllowVnetInBound at 65000).
  security_rule {
    name                       = "DenyAllOtherInbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Name = "${var.project}-app-nsg"
  }
}

# NSG for the database subnet.
# Allows MySQL (port 3306) from app subnets only; denies everything else.
resource "azurerm_network_security_group" "db_nsg" {
  name                = "${var.project}-db-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "AllowMySQLFromAppSubnet1"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = var.app_subnet_1_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowMySQLFromAppSubnet2"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = var.app_subnet_2_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "DenyAllOtherInbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Name = "${var.project}-db-nsg"
  }
}

# Associate NSGs with their respective subnets.
# In Azure, NSGs are applied at the subnet level (unlike AWS where they attach to instances).
resource "azurerm_subnet_network_security_group_association" "web_subnet_1_nsg" {
  subnet_id                 = var.web_subnet_1_id
  network_security_group_id = azurerm_network_security_group.web_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "web_subnet_2_nsg" {
  subnet_id                 = var.web_subnet_2_id
  network_security_group_id = azurerm_network_security_group.web_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "app_subnet_1_nsg" {
  subnet_id                 = var.app_subnet_1_id
  network_security_group_id = azurerm_network_security_group.app_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "app_subnet_2_nsg" {
  subnet_id                 = var.app_subnet_2_id
  network_security_group_id = azurerm_network_security_group.app_nsg.id
}

# NSG association for the delegated database subnet.
resource "azurerm_subnet_network_security_group_association" "db_subnet_1_nsg" {
  subnet_id                 = var.db_subnet_1_id
  network_security_group_id = azurerm_network_security_group.db_nsg.id
}
