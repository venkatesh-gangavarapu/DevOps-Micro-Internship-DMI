# Azure Database for MySQL Flexible Server (replaces AWS RDS MySQL).
# Uses VNet integration via a delegated subnet — no public internet endpoint.
resource "azurerm_mysql_flexible_server" "book_review_db" {
  name                   = "${var.project}-mysql-server"
  location               = var.location
  resource_group_name    = var.resource_group_name
  administrator_login    = var.db_admin_username
  administrator_password = var.db_admin_password
  sku_name               = var.db_sku_name
  version                = var.mysql_version

  # VNet integration: the server is injected into the delegated subnet.
  # Replaces the RDS subnet group — no cross-subnet HA is needed here.
  delegated_subnet_id = var.db_subnet_id
  private_dns_zone_id = var.private_dns_zone_id

  storage {
    size_gb           = var.db_storage_size_gb
    auto_grow_enabled = true
  }

  zone = "1"

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  tags = {
    Name = "${var.project}-mysql-server"
  }
}

# Create the application database within the MySQL server.
# Replaces the db_name attribute on aws_db_instance.
resource "azurerm_mysql_flexible_database" "book_review" {
  name                = var.db_name
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.book_review_db.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}
