# ─────────────────────────────────────────────────────────
# variables.tf — Input Variables
# DevOps Micro Internship · Week 10
# ─────────────────────────────────────────────────────────

variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "terraform-vm-rg"
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "East US"
}

variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
  default     = "terraform-vm"
}

variable "vm_size" {
  description = "Azure VM SKU/size"
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Administrator username for the VM"
  type        = string
  default     = "adminuser"
}

variable "admin_password" {
  description = "Administrator password (use a strong password in production)"
  type        = string
  sensitive   = true
  default     = "P@ssw0rd1234!"
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default = {
    Project     = "dmi-week10"
    ManagedBy   = "terraform"
    Environment = "learning"
    Week        = "10"
    Author      = "venkatesh-gangavarapu"
  }
}
