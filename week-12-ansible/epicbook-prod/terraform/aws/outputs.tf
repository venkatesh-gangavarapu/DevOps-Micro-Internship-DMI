output "public_ip" {
  description = "Public IP of the EpicBook web server"
  value       = aws_instance.web.public_ip
}

output "admin_user" {
  description = "Default SSH user for Ubuntu AMIs"
  value       = "ubuntu"
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.web.id
}

output "ssh_command" {
  description = "Ready-to-paste SSH command"
  value       = "ssh ubuntu@${aws_instance.web.public_ip}"
}
