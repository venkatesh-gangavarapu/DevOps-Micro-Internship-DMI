output "public_ip" {
  description = "Public IP of the EpicBook web server"
  value       = azurerm_public_ip.pip.ip_address
}

output "admin_user" {
  description = "Admin SSH username"
  value       = azurerm_linux_virtual_machine.vm.admin_username
}

output "vm_id" {
  description = "Azure VM resource ID"
  value       = azurerm_linux_virtual_machine.vm.id
}

output "ssh_command" {
  description = "Ready-to-paste SSH command"
  value       = "ssh ${azurerm_linux_virtual_machine.vm.admin_username}@${azurerm_public_ip.pip.ip_address}"
}

output "resource_group" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.rg.name
}

output "mysql_host" {
  value = azurerm_mysql_flexible_server.main.fqdn
}

output "mysql_user" {
  value = azurerm_mysql_flexible_server.main.administrator_login
}

output "mysql_database" {
  value = azurerm_mysql_flexible_database.main.name
}