terraform {
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

module "networking" {
  source = "./modules/networking"

  project           = var.project
  location          = var.azure_location
  vpc_cidr_block    = var.vpc_cidr_block
  web_subnet_1_cidr = var.web_subnet_1_cidr
  web_subnet_2_cidr = var.web_subnet_2_cidr
  app_subnet_1_cidr = var.app_subnet_1_cidr
  app_subnet_2_cidr = var.app_subnet_2_cidr
  db_subnet_1_cidr  = var.db_subnet_1_cidr
  db_subnet_2_cidr  = var.db_subnet_2_cidr
}

module "security" {
  source = "./modules/security"

  project             = var.project
  location            = var.azure_location
  resource_group_name = module.networking.resource_group_name
  web_subnet_1_id     = module.networking.web_subnet_1_id
  web_subnet_2_id     = module.networking.web_subnet_2_id
  app_subnet_1_id     = module.networking.app_subnet_1_id
  app_subnet_2_id     = module.networking.app_subnet_2_id
  db_subnet_1_id      = module.networking.db_subnet_1_id
  web_subnet_1_cidr   = var.web_subnet_1_cidr
  web_subnet_2_cidr   = var.web_subnet_2_cidr
  app_subnet_1_cidr   = var.app_subnet_1_cidr
  app_subnet_2_cidr   = var.app_subnet_2_cidr
}

# The public LB IP is pre-allocated in the networking module.
# This cleanly breaks the circular dependency that existed in the original AWS version,
# where ec2 needed alb DNS names in user_data, while alb needed ec2 instance IDs.
module "compute" {
  source = "./modules/compute"

  project             = var.project
  location            = var.azure_location
  resource_group_name = module.networking.resource_group_name
  web_subnet_1_id     = module.networking.web_subnet_1_id
  app_subnet_1_id     = module.networking.app_subnet_1_id
  admin_username      = var.admin_username
  ssh_public_key      = var.ssh_public_key
  web_vm_size         = var.web_vm_size
  app_vm_size         = var.app_vm_size

  web_user_data = templatefile("${path.root}/scripts/frontend-userdata.sh", {
    public_lb_ip  = module.networking.public_lb_ip
    private_lb_ip = module.networking.private_lb_ip
  })

  app_user_data = templatefile("${path.root}/scripts/backend-userdata.sh", {
    db_host      = module.database.db_host
    db_user      = var.db_admin_username
    db_pass      = var.db_admin_password
    db_name      = var.db_name
    public_lb_ip = module.networking.public_lb_ip
  })
}

module "database" {
  source = "./modules/database"

  project             = var.project
  location            = var.azure_location
  resource_group_name = module.networking.resource_group_name
  db_subnet_id        = module.networking.db_subnet_1_id
  private_dns_zone_id = module.networking.mysql_private_dns_zone_id
  db_name             = var.db_name
  db_admin_username   = var.db_admin_username
  db_admin_password   = var.db_admin_password
  db_sku_name         = var.db_sku_name
  db_storage_size_gb  = var.db_storage_size_gb
  mysql_version       = var.mysql_version
}

module "loadbalancer" {
  source = "./modules/loadbalancer"

  project                = var.project
  location               = var.azure_location
  resource_group_name    = module.networking.resource_group_name
  public_lb_pip_id       = module.networking.public_lb_pip_id
  app_subnet_1_id        = module.networking.app_subnet_1_id
  private_lb_ip          = module.networking.private_lb_ip
  web_server_nic_id      = module.compute.web_server_nic_id
  app_server_nic_id      = module.compute.app_server_nic_id
  web_nic_ip_config_name = module.compute.web_nic_ip_config_name
  app_nic_ip_config_name = module.compute.app_nic_ip_config_name
}
