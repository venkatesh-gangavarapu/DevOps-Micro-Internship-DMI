# variables.tf
variable "resource_group_name" {
  description = "Azure Resource Group name"
  type        = string
  default     = "react-app-rg"
}
variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}
variable "vm_name" {
  description = "Virtual machine name"
  type        = string
  default     = "react-vm"
}
variable "vm_size" {
  description = "VM SKU size"
  type        = string
  default     = "Standard_B1s"
}
variable "admin_username" {
  description = "VM admin username"
  type        = string
  default     = "azureuser"
}
variable "admin_password" {
  description = "VM admin password"
  type        = string
  sensitive   = true
  default     = "P@ssw0rd1234!"
}
variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default = {
    Project     = "dmi-week10-react"
    ManagedBy   = "terraform"
    Environment = "learning"
    Week        = "10"
    Assignment  = "3"
    Author      = "venkatesh-gangavarapu"
  }
}
