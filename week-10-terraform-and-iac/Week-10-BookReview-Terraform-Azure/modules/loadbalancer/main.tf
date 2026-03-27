# Public-facing Standard Load Balancer for the web tier (replaces AWS public ALB).
# Uses the public IP pre-allocated in the networking module.
resource "azurerm_lb" "public_lb" {
  name                = "${var.project}-public-lb"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "public-lb-frontend"
    public_ip_address_id = var.public_lb_pip_id
  }

  tags = {
    Name = "${var.project}-public-lb"
  }
}

# Backend pool for web server VMs.
resource "azurerm_lb_backend_address_pool" "web_pool" {
  loadbalancer_id = azurerm_lb.public_lb.id
  name            = "${var.project}-web-backend-pool"
}

# TCP health probe for web servers on port 80.
resource "azurerm_lb_probe" "web_probe" {
  loadbalancer_id     = azurerm_lb.public_lb.id
  name                = "${var.project}-web-probe"
  port                = 80
  protocol            = "Tcp"
  interval_in_seconds = 30
  number_of_probes    = 2
}

# Forward internet traffic on port 80 to the web backend pool.
# disable_outbound_snat = true because web VMs have their own public IPs for outbound.
resource "azurerm_lb_rule" "web_rule" {
  loadbalancer_id                = azurerm_lb.public_lb.id
  name                           = "${var.project}-web-lb-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "public-lb-frontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.web_pool.id]
  probe_id                       = azurerm_lb_probe.web_probe.id
  disable_outbound_snat          = true
}

# Register the web server NIC in the public LB backend pool.
resource "azurerm_network_interface_backend_address_pool_association" "web_nic_assoc" {
  network_interface_id    = var.web_server_nic_id
  ip_configuration_name   = var.web_nic_ip_config_name
  backend_address_pool_id = azurerm_lb_backend_address_pool.web_pool.id
}

# Internal Standard Load Balancer for the app tier (replaces AWS internal ALB).
# Uses a static private IP from the app subnet so the address is predictable.
resource "azurerm_lb" "internal_lb" {
  name                = "${var.project}-internal-lb"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "internal-lb-frontend"
    subnet_id                     = var.app_subnet_1_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.private_lb_ip
  }

  tags = {
    Name = "${var.project}-internal-lb"
  }
}

# Backend pool for app server VMs.
resource "azurerm_lb_backend_address_pool" "app_pool" {
  loadbalancer_id = azurerm_lb.internal_lb.id
  name            = "${var.project}-app-backend-pool"
}

# TCP health probe for app servers on port 3001.
resource "azurerm_lb_probe" "app_probe" {
  loadbalancer_id     = azurerm_lb.internal_lb.id
  name                = "${var.project}-app-probe"
  port                = 3001
  protocol            = "Tcp"
  interval_in_seconds = 30
  number_of_probes    = 2
}

# Forward internal traffic on port 3001 to the app backend pool.
# disable_outbound_snat = true because app VMs use NAT Gateway for outbound.
resource "azurerm_lb_rule" "app_rule" {
  loadbalancer_id                = azurerm_lb.internal_lb.id
  name                           = "${var.project}-app-lb-rule"
  protocol                       = "Tcp"
  frontend_port                  = 3001
  backend_port                   = 3001
  frontend_ip_configuration_name = "internal-lb-frontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.app_pool.id]
  probe_id                       = azurerm_lb_probe.app_probe.id
  disable_outbound_snat          = true
}

# Register the app server NIC in the internal LB backend pool.
resource "azurerm_network_interface_backend_address_pool_association" "app_nic_assoc" {
  network_interface_id    = var.app_server_nic_id
  ip_configuration_name   = var.app_nic_ip_config_name
  backend_address_pool_id = azurerm_lb_backend_address_pool.app_pool.id
}
