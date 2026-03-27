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

# Subnet IDs for NSG-to-subnet associations.
variable "web_subnet_1_id" {
  description = "ID of the first web subnet for NSG association"
  type        = string
}

variable "web_subnet_2_id" {
  description = "ID of the second web subnet for NSG association"
  type        = string
}

variable "app_subnet_1_id" {
  description = "ID of the first app subnet for NSG association"
  type        = string
}

variable "app_subnet_2_id" {
  description = "ID of the second app subnet for NSG association"
  type        = string
}

variable "db_subnet_1_id" {
  description = "ID of the primary database subnet for NSG association"
  type        = string
}

# Subnet CIDRs used as source address prefixes in NSG rules.
# Azure NSGs use IP ranges instead of security group references (unlike AWS).
variable "web_subnet_1_cidr" {
  description = "CIDR of web subnet 1, used as source in app NSG allow rules"
  type        = string
}

variable "web_subnet_2_cidr" {
  description = "CIDR of web subnet 2, used as source in app NSG allow rules"
  type        = string
}

variable "app_subnet_1_cidr" {
  description = "CIDR of app subnet 1, used as source in db NSG allow rules"
  type        = string
}

variable "app_subnet_2_cidr" {
  description = "CIDR of app subnet 2, used as source in db NSG allow rules"
  type        = string
}
