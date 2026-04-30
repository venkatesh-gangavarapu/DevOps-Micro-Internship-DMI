variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project identifier used as resource name prefix"
  type        = string
  default     = "book-review"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "eks_cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.29"
}

variable "eks_node_instance_type" {
  description = "EC2 instance type for EKS managed node group"
  type        = string
  default     = "t3.medium"
}

variable "eks_node_desired_size" {
  type    = number
  default = 2
}

variable "eks_node_min_size" {
  type    = number
  default = 1
}

variable "eks_node_max_size" {
  type    = number
  default = 4
}

variable "db_name" {
  description = "Aurora database name"
  type        = string
  default     = "book_review_db"
}

variable "db_username" {
  description = "Aurora master username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Aurora master password — pass via TF_VAR_db_password or pipeline secret"
  type        = string
  sensitive   = true
}
