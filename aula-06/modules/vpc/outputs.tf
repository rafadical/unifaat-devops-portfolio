output "vpc_id" {
  description = "ID da VPC criada."
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR da VPC (útil para regras de Security Group)."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "IDs das subnets públicas, ordenados pelo nome lógico."
  value       = [for k in sort(keys(local.public_subnets)) : aws_subnet.this[k].id]
}

output "private_subnet_ids" {
  description = "IDs das subnets privadas, ordenados pelo nome lógico."
  value       = [for k in sort(keys(local.private_subnets)) : aws_subnet.this[k].id]
}
