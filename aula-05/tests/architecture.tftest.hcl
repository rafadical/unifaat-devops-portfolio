mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = { names = ["us-east-1a", "us-east-1b"] }
  }
  mock_data "aws_ami" {
    defaults = { id = "ami-0123456789abcdef0" }
  }
}

variables {
  ssh_cidr = "203.0.113.10/32"
  # O provider é simulado: este arquivo testa a leitura local, sem enviar chave à AWS.
  ssh_public_key_path = "tests/architecture.tftest.hcl"
  db_password         = "MockOnly-TestPassword123!"
}

run "private_database_and_network" {
  command = plan
  assert {
    condition     = aws_vpc.main.cidr_block == "10.0.0.0/16" && length(aws_subnet.private) == 2 && aws_subnet.private[0].availability_zone != aws_subnet.private[1].availability_zone
    error_message = "A rede deve conter duas subnets privadas em AZs distintas."
  }
  assert {
    condition     = !aws_db_instance.database.publicly_accessible && !aws_db_instance.database.multi_az && aws_db_instance.database.storage_encrypted && aws_db_instance.database.instance_class == "db.t3.micro" && aws_db_instance.database.allocated_storage == 20 && aws_db_instance.database.storage_type == "gp2" && aws_db_instance.database.engine_version == "15"
    error_message = "O RDS precisa seguir os parâmetros e isolamento do TF."
  }
  assert {
    condition     = length(aws_route_table.private.route) == 0 && length(aws_route_table.public.route) == 1
    error_message = "Apenas a tabela pública deve ter uma rota extra para internet."
  }
  assert {
    condition     = alltrue([for rule in aws_security_group.rds.ingress : rule.from_port == 5432 && rule.to_port == 5432 && (rule.cidr_blocks == null ? true : length(rule.cidr_blocks) == 0) && length(rule.security_groups) == 1])
    error_message = "O banco deve permitir 5432 por referência ao SG, sem CIDR público."
  }
  assert {
    condition     = aws_instance.app.instance_type == "t2.micro" && aws_instance.app.metadata_options[0].http_tokens == "required"
    error_message = "A EC2 deve ser t2.micro e exigir IMDSv2."
  }
}

run "reject_public_ssh" {
  command = plan
  variables { ssh_cidr = "0.0.0.0/0" }
  expect_failures = [var.ssh_cidr]
}

run "reject_short_password" {
  command = plan
  variables { db_password = "short" }
  expect_failures = [var.db_password]
}

