# ── Resource Group ──────────────────────────
resource "azurerm_resource_group" "main" {
  name     = "rg-react-cicd"
  location = "Central India"
}

# ── Virtual Network ─────────────────────────
resource "azurerm_virtual_network" "main" {
  name                = "vnet-react-cicd"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# ── Subnet ──────────────────────────────────
resource "azurerm_subnet" "main" {
  name                 = "subnet-react-cicd"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# ── NSG ─────────────────────────────────────
resource "azurerm_network_security_group" "main" {
  name                = "nsg-react-cicd"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-http"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-https"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# ── NSG → Subnet ────────────────────────────
resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = azurerm_subnet.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# ── Public IP ───────────────────────────────
resource "azurerm_public_ip" "main" {
  name                = "pip-react-cicd"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# ── NIC ─────────────────────────────────────
resource "azurerm_network_interface" "main" {
  name                = "nic-react-cicd"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

# ── VM ──────────────────────────────────────
resource "azurerm_linux_virtual_machine" "main" {
  name                = "vm-react-cicd"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = "Standard_B2s"
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.main.id
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_ed25519.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 64
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  tags = {
    project = "react-cicd"
    week    = "13"
  }
}

# ── Outputs ──────────────────────────────────
output "public_ip" {
  description = "Public IP of the VM"
  value       = azurerm_linux_virtual_machine.main.public_ip_address
}

output "admin_user" {
  description = "Admin username"
  value       = azurerm_linux_virtual_machine.main.admin_username
}

