variable "project" {
  description = "The name of the project"
  type        = string
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
}

# The subnet delegated to Microsoft.DBforMySQL/flexibleServers.
variable "db_subnet_id" {
  description = "ID of the subnet delegated to MySQL Flexible Server"
  type        = string
}

# Private DNS zone ID required for VNet-integrated MySQL Flexible Server.
variable "private_dns_zone_id" {
  description = "ID of the private DNS zone for MySQL Flexible Server"
  type        = string
}

# Name of the MySQL database to create inside the server.
variable "db_name" {
  description = "The name of the MySQL database to create"
  type        = string
}

# MySQL admin login (cannot be 'admin', 'administrator', 'root', 'guest', or 'public').
variable "db_admin_username" {
  description = "The administrator login for MySQL Flexible Server"
  type        = string
}

# MySQL admin password (sensitive — store in terraform.tfvars, never commit).
variable "db_admin_password" {
  description = "The administrator password for MySQL Flexible Server"
  type        = string
  sensitive   = true
}

# MySQL Flexible Server SKU (e.g. B_Standard_B1ms for Burstable tier).
variable "db_sku_name" {
  description = "The SKU name for MySQL Flexible Server"
  type        = string
}

# Storage size in GB (minimum 20).
variable "db_storage_size_gb" {
  description = "The storage size in GB for MySQL Flexible Server"
  type        = number
}

# MySQL version to deploy (5.7 or 8.0.21).
variable "mysql_version" {
  description = "The MySQL engine version (5.7 or 8.0.21)"
  type        = string
}
