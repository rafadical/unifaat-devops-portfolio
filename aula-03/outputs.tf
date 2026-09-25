output "developers_group_name" {
  description = "Nome do grupo de developers"
  value       = aws_iam_group.developers.name
}

output "platform_eng_group_name" {
  description = "Nome do grupo de plataforma"
  value       = aws_iam_group.platform_eng.name
}

output "users" {
  description = "Lista de usuários criados"
  value = {
    juliana_dev     = aws_iam_user.juliana_dev.name
    rafael_platform = aws_iam_user.rafael_platform.name
    lucas_intern    = aws_iam_user.lucas_intern.name
  }
}

output "custom_policies" {
  description = "Policies customizadas criadas"
  value = {
    s3_read            = aws_iam_policy.s3_read.arn
    ec2_s3_full        = aws_iam_policy.ec2_s3_full.arn
    deny_destructive   = aws_iam_policy.deny_destructive.arn
  }
}

output "ec2_role_arn" {
  description = "ARN do papel EC2 para acesso ao S3"
  value       = aws_iam_role.ec2_role.arn
}

output "ec2_instance_profile" {
  description = "Nome do instance profile do EC2"
  value       = aws_iam_instance_profile.ec2_profile.name
}
