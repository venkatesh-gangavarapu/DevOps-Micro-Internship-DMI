# ─────────────────────────────────────────────────────────
# provider.tf — AzureRM Provider Configuration
# DevOps Micro Internship · Week 10
# ─────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}
