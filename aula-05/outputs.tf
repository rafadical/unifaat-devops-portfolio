output "vpc_id" {
  value = aws_vpc.main.id
}
output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}
output "ec2_public_ip" {
  value = aws_instance.app.public_ip
}
output "ec2_instance_id" {
  value = aws_instance.app.id
}
output "rds_endpoint" {
  value = aws_db_instance.database.endpoint
}
output "rds_address" {
  value = aws_db_instance.database.address
}
output "connection_string" {
  value = "psql \"host=${aws_db_instance.database.address} port=5432 dbname=${var.db_name} user=${var.db_username} sslmode=require\" -W"
}
