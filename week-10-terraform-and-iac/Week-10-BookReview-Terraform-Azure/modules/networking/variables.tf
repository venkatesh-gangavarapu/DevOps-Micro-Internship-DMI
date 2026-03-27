# Project name used for naming and tagging all network resources.
variable "project" {
  description = "The name of the project"
  type        = string
}

# Azure region where all resources will be created.
variable "location" {
  description = "Azure region for all resources (e.g. eastus, westeurope)"
  type        = string
}

# Address space for the Virtual Network (replaces AWS VPC CIDR).
variable "vpc_cidr_block" {
  description = "The address space for the Azure Virtual Network"
  type        = string
}

# CIDR range for web subnet 1.
variable "web_subnet_1_cidr" {
  description = "The CIDR block for the first web subnet"
  type        = string
}

# CIDR range for web subnet 2.
variable "web_subnet_2_cidr" {
  description = "The CIDR block for the second web subnet"
  type        = string
}

# CIDR range for app subnet 1.
variable "app_subnet_1_cidr" {
  description = "The CIDR block for the first app subnet"
  type        = string
}

# CIDR range for app subnet 2.
variable "app_subnet_2_cidr" {
  description = "The CIDR block for the second app subnet"
  type        = string
}

# CIDR range for the primary database subnet (will be delegated to MySQL Flexible Server).
variable "db_subnet_1_cidr" {
  description = "The CIDR block for the primary database subnet"
  type        = string
}

# CIDR range for the secondary database subnet.
variable "db_subnet_2_cidr" {
  description = "The CIDR block for the secondary database subnet"
  type        = string
}
