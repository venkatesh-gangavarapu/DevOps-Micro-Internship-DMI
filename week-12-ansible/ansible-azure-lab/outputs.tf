output "public_ips" {
  value = {
    for k, v in azurerm_public_ip.pip : k => v.ip_address
  }
}
