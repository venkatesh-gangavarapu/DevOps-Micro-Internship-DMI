# Public IP for the web server VM.
# Provides direct SSH access and outbound internet for package installations.
resource "azurerm_public_ip" "web_server_pip" {
  name                = "${var.project}-web-server-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Name = "${var.project}-web-server-pip"
  }
}

# Network Interface for the web server (placed in public web subnet with public IP).
resource "azurerm_network_interface" "web_server_nic" {
  name                = "${var.project}-web-server-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = local.web_ip_config_name
    subnet_id                     = var.web_subnet_1_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web_server_pip.id
  }

  tags = {
    Name = "${var.project}-web-server-nic"
  }
}

# Web server VM running Ubuntu 24.04 with Next.js frontend served via Nginx.
# Replaces the AWS EC2 web_server instance.
resource "azurerm_linux_virtual_machine" "web_server" {
  name                = "${var.project}-web-server"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.web_vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.web_server_nic.id
  ]

  # Azure uses SSH public key content directly; AWS used a named key pair.
  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  # os_disk is required in Azure (implicit in AWS aws_instance).
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # Ubuntu 24.04 LTS from Canonical (replaces data.aws_ami.ubuntu lookup).
  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  # Azure requires custom_data to be base64 encoded (AWS user_data accepts raw strings).
  custom_data = base64encode(var.web_user_data)

  tags = {
    Name = "${var.project}-web-server"
  }
}

# Network Interface for the app server (placed in private app subnet, no public IP).
resource "azurerm_network_interface" "app_server_nic" {
  name                = "${var.project}-app-server-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = local.app_ip_config_name
    subnet_id                     = var.app_subnet_1_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    Name = "${var.project}-app-server-nic"
  }
}

# App server VM running Ubuntu 24.04 with Node.js backend on port 3001.
# Placed in a private subnet; outbound internet access via NAT Gateway.
resource "azurerm_linux_virtual_machine" "app_server" {
  name                = "${var.project}-app-server"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.app_vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.app_server_nic.id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  custom_data = base64encode(var.app_user_data)

  tags = {
    Name = "${var.project}-app-server"
  }
}

# IP configuration names must match between NIC and backend pool association resources.
locals {
  web_ip_config_name = "web-ipconfig"
  app_ip_config_name = "app-ipconfig"
}
