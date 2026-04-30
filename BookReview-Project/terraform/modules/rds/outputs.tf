output "cluster_endpoint" {
  description = "Aurora writer endpoint"
  value       = aws_rds_cluster.this.endpoint
}
output "reader_endpoint" {
  value = aws_rds_cluster.this.reader_endpoint
}
output "cluster_identifier" {
  value = aws_rds_cluster.this.cluster_identifier
}
