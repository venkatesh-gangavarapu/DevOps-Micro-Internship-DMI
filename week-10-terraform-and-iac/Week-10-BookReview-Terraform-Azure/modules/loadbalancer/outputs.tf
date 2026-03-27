# Resource ID of the public load balancer.
output "public_lb_id" {
  description = "Resource ID of the internet-facing public load balancer"
  value       = azurerm_lb.public_lb.id
}

# Resource ID of the internal load balancer.
output "internal_lb_id" {
  description = "Resource ID of the internal load balancer"
  value       = azurerm_lb.internal_lb.id
}
