# Resource group name shared with all other modules.
output "resource_group_name" {
  description = "Name of the Azure Resource Group containing all project resources"
  value       = azurerm_resource_group.rg.name
}

# VNet ID used by the security module for NSG associations.
output "vnet_id" {
  description = "ID of the Azure Virtual Network"
  value       = azurerm_virtual_network.vnet.id
}

# ID of web subnet 1.
output "web_subnet_1_id" {
  value = azurerm_subnet.web_subnet_1.id
}

# ID of web subnet 2.
output "web_subnet_2_id" {
  value = azurerm_subnet.web_subnet_2.id
}

# ID of app subnet 1.
output "app_subnet_1_id" {
  value = azurerm_subnet.app_subnet_1.id
}

# ID of app subnet 2.
output "app_subnet_2_id" {
  value = azurerm_subnet.app_subnet_2.id
}

# ID of the delegated database subnet (used by MySQL Flexible Server).
output "db_subnet_1_id" {
  value = azurerm_subnet.db_subnet_1.id
}

# ID of the secondary database subnet.
output "db_subnet_2_id" {
  value = azurerm_subnet.db_subnet_2.id
}

# Resource ID of the pre-allocated public LB IP, passed to the loadbalancer module.
output "public_lb_pip_id" {
  description = "Resource ID of the public IP pre-allocated for the public load balancer"
  value       = azurerm_public_ip.public_lb_pip.id
}

# Actual IP address of the public LB, used in user_data scripts and application URLs.
output "public_lb_ip" {
  description = "Public IP address of the internet-facing load balancer"
  value       = azurerm_public_ip.public_lb_pip.ip_address
}

# Static private IP reserved for the internal load balancer frontend.
output "private_lb_ip" {
  description = "Static private IP address reserved for the internal load balancer"
  value       = local.private_lb_ip
}

# DNS zone ID passed to the database module for MySQL Flexible Server.
output "mysql_private_dns_zone_id" {
  description = "ID of the private DNS zone for MySQL Flexible Server VNet integration"
  value       = azurerm_private_dns_zone.mysql.id
}
