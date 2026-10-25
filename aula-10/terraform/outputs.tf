output "ec2_public_ip" {
  description = "Valor do secret EC2_HOST."
  value       = aws_eip.app.public_ip
}

output "ec2_instance_id" {
  value = aws_instance.app.id
}

output "ecr_repository_url" {
  value = aws_ecr_repository.technova_api.repository_url
}

output "security_group_id" {
  value = aws_security_group.technova_api.id
}

output "health_url" {
  value = "http://${aws_eip.app.public_ip}:${var.app_port}/health"
}
