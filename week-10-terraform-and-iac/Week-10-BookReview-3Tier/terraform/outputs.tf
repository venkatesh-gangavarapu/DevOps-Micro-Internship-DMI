# outputs.tf
output "public_alb_dns"    { value = aws_lb.public.dns_name }
output "internal_alb_dns"  { value = aws_lb.internal.dns_name }
output "app_url"            { value = "http://${aws_lb.public.dns_name}" }
output "rds_primary_endpoint" { value = aws_db_instance.primary.endpoint }
output "rds_replica_endpoint" { value = aws_db_instance.replica.endpoint }
