# Public IP address of the web server VM (for SSH access).
output "web_server_pub_ip" {
  description = "Public IP address of the web server"
  value       = azurerm_public_ip.web_server_pip.ip_address
}

# Private IP address of the app server (no public IP assigned).
output "app_server_prvt_ip" {
  description = "Private IP address of the app server"
  value       = azurerm_network_interface.app_server_nic.private_ip_address
}

# NIC ID used by the loadbalancer module to associate the web VM with the backend pool.
output "web_server_nic_id" {
  description = "Resource ID of the web server NIC"
  value       = azurerm_network_interface.web_server_nic.id
}

# NIC ID used by the loadbalancer module to associate the app VM with the backend pool.
output "app_server_nic_id" {
  description = "Resource ID of the app server NIC"
  value       = azurerm_network_interface.app_server_nic.id
}

# IP configuration name of the web NIC, required by azurerm_network_interface_backend_address_pool_association.
output "web_nic_ip_config_name" {
  description = "IP configuration name used in the web server NIC"
  value       = local.web_ip_config_name
}

# IP configuration name of the app NIC, required by azurerm_network_interface_backend_address_pool_association.
output "app_nic_ip_config_name" {
  description = "IP configuration name used in the app server NIC"
  value       = local.app_ip_config_name
}
