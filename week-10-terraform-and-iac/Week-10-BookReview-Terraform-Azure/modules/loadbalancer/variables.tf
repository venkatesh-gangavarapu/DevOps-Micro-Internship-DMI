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

# Pre-allocated public IP resource ID (created in networking module to avoid circular dependency).
variable "public_lb_pip_id" {
  description = "Resource ID of the pre-allocated public IP for the public load balancer frontend"
  type        = string
}

# Subnet where the internal LB frontend IP is placed.
variable "app_subnet_1_id" {
  description = "Subnet ID for the internal load balancer frontend IP configuration"
  type        = string
}

# Static private IP for the internal LB frontend (pre-computed in networking module).
variable "private_lb_ip" {
  description = "Static private IP address for the internal load balancer frontend"
  type        = string
}

# NIC IDs from the compute module — used to associate VMs with backend pools.
variable "web_server_nic_id" {
  description = "Resource ID of the web server NIC"
  type        = string
}

variable "app_server_nic_id" {
  description = "Resource ID of the app server NIC"
  type        = string
}

# IP configuration names must match exactly what is defined in the NIC resources.
variable "web_nic_ip_config_name" {
  description = "IP configuration name of the web server NIC"
  type        = string
}

variable "app_nic_ip_config_name" {
  description = "IP configuration name of the app server NIC"
  type        = string
}
