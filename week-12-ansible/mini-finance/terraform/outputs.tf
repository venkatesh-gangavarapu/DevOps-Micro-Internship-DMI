# ── Output ─────────────────────────────────
output "public_ip" {
  description = "Public IP of the Mini Finance VM"
  value       = azurerm_linux_virtual_machine.vm.public_ip_address
}
