# outputs.tf
output "ec2_public_ip" { value = aws_instance.web.public_ip }
output "rds_endpoint"  { value = aws_db_instance.mysql.endpoint }
output "app_url"       { value = "http://${aws_instance.web.public_ip}" }
output "ssh_command"   { value = "ssh -i ${var.key_pair_name}.pem ubuntu@${aws_instance.web.public_ip}" }
output "db_connect"    { value = "mysql -h ${aws_db_instance.mysql.endpoint} -u ${var.db_username} -p" }
