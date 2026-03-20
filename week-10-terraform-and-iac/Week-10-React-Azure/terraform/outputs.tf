# outputs.tf
output "public_ip" {
  description = "Public IP of the VM — visit http://<public_ip> for the React app"
  value       = azurerm_public_ip.pip.ip_address
}
output "vm_name" {
  description = "VM name"
  value       = azurerm_linux_virtual_machine.vm.name
}
output "ssh_command" {
  description = "SSH command to connect"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.pip.ip_address}"
}
output "react_app_url" {
  description = "URL to visit the deployed React app"
  value       = "http://${azurerm_public_ip.pip.ip_address}"
}
