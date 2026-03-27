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

# Subnet where the web server NIC is placed.
variable "web_subnet_1_id" {
  description = "Subnet ID for the web server NIC"
  type        = string
}

# Subnet where the app server NIC is placed.
variable "app_subnet_1_id" {
  description = "Subnet ID for the app server NIC"
  type        = string
}

# Admin username for both VMs.
variable "admin_username" {
  description = "Admin username for the Linux Virtual Machines"
  type        = string
}

# SSH public key content (replaces AWS key pair name).
variable "ssh_public_key" {
  description = "SSH public key content for VM authentication"
  type        = string
  sensitive   = true
}

# Azure VM size for the web server (e.g. Standard_B2s replaces t3.micro).
variable "web_vm_size" {
  description = "Azure VM size for the web server"
  type        = string
}

# Azure VM size for the app server.
variable "app_vm_size" {
  description = "Azure VM size for the app server"
  type        = string
}

# Rendered cloud-init script for the web server.
variable "web_user_data" {
  description = "Rendered user-data script for the web server (will be base64 encoded)"
  type        = string
}

# Rendered cloud-init script for the app server.
variable "app_user_data" {
  description = "Rendered user-data script for the app server (will be base64 encoded)"
  type        = string
}
