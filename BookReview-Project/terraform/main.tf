locals {
  name = "${var.project_name}-${var.environment}"
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

module "vpc" {
  source = "./modules/vpc"
  name   = local.name
  cidr   = var.vpc_cidr
  tags   = local.tags
}

module "eks" {
  source             = "./modules/eks"
  name               = local.name
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  cluster_version    = var.eks_cluster_version
  node_instance_type = var.eks_node_instance_type
  node_desired_size  = var.eks_node_desired_size
  node_min_size      = var.eks_node_min_size
  node_max_size      = var.eks_node_max_size
  tags               = local.tags
}

module "rds" {
  source         = "./modules/rds"
  name           = local.name
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.private_subnet_ids
  eks_node_sg_id = module.eks.node_security_group_id
  db_name        = var.db_name
  db_username    = var.db_username
  db_password    = var.db_password
  tags           = local.tags
}
