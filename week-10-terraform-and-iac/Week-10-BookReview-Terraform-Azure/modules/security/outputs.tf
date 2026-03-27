# NSG IDs exported for reference. NSG-subnet associations are handled inside this module,
# so these IDs are not consumed by compute or loadbalancer modules.
output "web_nsg_id" {
  description = "ID of the web tier Network Security Group"
  value       = azurerm_network_security_group.web_nsg.id
}

output "app_nsg_id" {
  description = "ID of the app tier Network Security Group"
  value       = azurerm_network_security_group.app_nsg.id
}

output "db_nsg_id" {
  description = "ID of the database tier Network Security Group"
  value       = azurerm_network_security_group.db_nsg.id
}
