# ─────────────────────────────────────────────────────────
# outputs.tf — Output Values
# DevOps Micro Internship · Week 10
# ─────────────────────────────────────────────────────────

output "public_ip_address" {
  description = "Public IP address of the Azure VM"
  value       = azurerm_public_ip.pip.ip_address
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = azurerm_linux_virtual_machine.vm.name
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.rg.name
}

output "admin_username" {
  description = "SSH admin username"
  value       = azurerm_linux_virtual_machine.vm.admin_username
}

output "ssh_command" {
  description = "SSH command to connect to the VM"
  value       = "ssh ${azurerm_linux_virtual_machine.vm.admin_username}@${azurerm_public_ip.pip.ip_address}"
}
