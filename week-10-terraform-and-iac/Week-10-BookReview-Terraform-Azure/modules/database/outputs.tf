# FQDN of the MySQL Flexible Server.
# Format: <server-name>.mysql.database.azure.com
# Use as DB_HOST in the backend application .env file.
output "db_endpoint" {
  description = "FQDN of the MySQL Flexible Server"
  value       = azurerm_mysql_flexible_server.book_review_db.fqdn
}

# Alias for db_endpoint, used in the root module app_user_data templatefile call.
output "db_host" {
  description = "Hostname of the MySQL Flexible Server (FQDN, no port suffix)"
  value       = azurerm_mysql_flexible_server.book_review_db.fqdn
}
