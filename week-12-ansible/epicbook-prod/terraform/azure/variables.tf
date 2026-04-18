variable "location" {
  description = "Azure region to deploy resources into"
  type        = string
  default     = "Central India"
}

variable "project_name" {
  description = "Prefix applied to all resource names"
  type        = string
  default     = "epicbook"
}

variable "vm_size" {
  description = "Azure VM size"
  type        = string
  default     = "Standard_B2s"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key uploaded to Azure"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "admin_username" {
  description = "Admin username for the Linux VM"
  type        = string
  default     = "azureuser"
}

variable "db_password" {
  description = "Administrator password for the MySQL Flexible Server"
  type        = string
  sensitive   = true
}
