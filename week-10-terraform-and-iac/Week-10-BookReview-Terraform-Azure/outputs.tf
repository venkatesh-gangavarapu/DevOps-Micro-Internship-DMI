output "webserver_pub_ip" {
  description = "Public IP address of the web server VM"
  value       = module.compute.web_server_pub_ip
}

output "appserver_prvt_ip" {
  description = "Private IP address of the app server VM"
  value       = module.compute.app_server_prvt_ip
}

output "db_endpoint" {
  description = "FQDN of the Azure MySQL Flexible Server (use as DB_HOST in application config)"
  value       = module.database.db_endpoint
}

output "public_lb_ip" {
  description = "Public IP address of the internet-facing load balancer (application entry point)"
  value       = module.networking.public_lb_ip
}

output "private_lb_ip" {
  description = "Private IP address of the internal load balancer"
  value       = module.networking.private_lb_ip
}
