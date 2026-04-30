output "eks_cluster_name" {
  description = "EKS cluster name — used in pipeline to configure kubectl"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "rds_endpoint" {
  description = "Aurora writer endpoint — set as DB_HOST in backend config"
  value       = module.rds.cluster_endpoint
}

output "rds_reader_endpoint" {
  value = module.rds.reader_endpoint
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
