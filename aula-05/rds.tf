resource "aws_db_subnet_group" "database" {
  name       = "${local.prefix}-db-subnets"
  subnet_ids = aws_subnet.private[*].id
  tags       = { Name = "${local.prefix}-db-subnets" }
}

resource "aws_security_group" "rds" {
  name   = "${local.prefix}-rds"
  vpc_id = aws_vpc.main.id
  ingress {
    description     = "PostgreSQL apenas da EC2"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }
  tags = { Name = "${local.prefix}-rds-sg" }
}

resource "aws_db_instance" "database" {
  identifier              = "${local.prefix}-db"
  engine                  = "postgres"
  engine_version          = "15"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  storage_type            = "gp2"
  storage_encrypted       = true
  multi_az                = false
  publicly_accessible     = false
  db_subnet_group_name    = aws_db_subnet_group.database.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  skip_final_snapshot     = true
  deletion_protection     = false
  backup_retention_period = 0
  tags                    = { Name = "${local.prefix}-db" }
}
