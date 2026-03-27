variable "azure_location" {
  description = "Azure region for all resources (e.g. eastus, westeurope, eastasia)"
  type        = string
  default     = "centralindia"
}

variable "project" {
  description = "The name of the project, used for naming and tagging all resources"
  type        = string
}

variable "vpc_cidr_block" {
  description = "The address space for the Azure Virtual Network (e.g. 10.0.0.0/16)"
  type        = string
}

variable "web_subnet_1_cidr" {
  description = "The CIDR block for the first web subnet"
  type        = string
}

variable "web_subnet_2_cidr" {
  description = "The CIDR block for the second web subnet"
  type        = string
}

variable "app_subnet_1_cidr" {
  description = "The CIDR block for the first app subnet"
  type        = string
}

variable "app_subnet_2_cidr" {
  description = "The CIDR block for the second app subnet"
  type        = string
}

variable "db_subnet_1_cidr" {
  description = "The CIDR block for the primary database subnet (delegated to MySQL Flexible Server)"
  type        = string
}

variable "db_subnet_2_cidr" {
  description = "The CIDR block for the secondary database subnet"
  type        = string
}

variable "admin_username" {
  description = "Admin username for the Azure Linux Virtual Machines"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key" {
  description = "SSH public key content for VM authentication (e.g. contents of ~/.ssh/id_rsa.pub)"
  type        = string
  sensitive   = true
}

variable "web_vm_size" {
  description = "Azure VM size for web servers (e.g. Standard_B2s)"
  type        = string
  default     = "Standard_B2s"
}

variable "app_vm_size" {
  description = "Azure VM size for app servers (e.g. Standard_B2s)"
  type        = string
  default     = "Standard_B2s"
}

variable "db_name" {
  description = "The name of the MySQL database to create"
  type        = string
}

variable "db_admin_username" {
  description = "The administrator login for MySQL Flexible Server (cannot be 'admin', 'root', or other reserved names)"
  type        = string
}

variable "db_admin_password" {
  description = "The administrator password for MySQL Flexible Server"
  type        = string
  sensitive   = true
}

variable "db_sku_name" {
  description = "The SKU name for MySQL Flexible Server (e.g. B_Standard_B1ms for Burstable, GP_Standard_D2ds_v4 for General Purpose)"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "db_storage_size_gb" {
  description = "The storage size in GB for MySQL Flexible Server (minimum 20)"
  type        = number
  default     = 20
}

variable "mysql_version" {
  description = "The MySQL engine version to use (5.7 or 8.0.21)"
  type        = string
  default     = "8.0.21"
}
