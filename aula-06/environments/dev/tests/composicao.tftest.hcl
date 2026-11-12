# Testa a composição dos módulos sem acessar a AWS (provider simulado).
# Executar em environments/dev:  terraform test

mock_provider "aws" {
  mock_data "aws_ami" {
    defaults = {
      id = "ami-0123456789abcdef0"
    }
  }
}

variables {
  db_password = "SenhaDeTeste123"
}

run "dev_cria_subnets_e_composicao" {
  command = apply

  assert {
    condition     = length(output.public_subnet_ids) == 2
    error_message = "Dev deve ter 2 subnets públicas."
  }

  assert {
    condition     = length(output.private_subnet_ids) == 2
    error_message = "Dev deve ter 2 subnets privadas para o DB Subnet Group."
  }

  assert {
    condition     = output.db_name == "technova_dev"
    error_message = "O database do dev deve se chamar technova_dev."
  }

  assert {
    condition     = output.api_sg_id != output.rds_sg_id
    error_message = "API e RDS devem ter Security Groups separados."
  }
}

run "staging_usa_os_mesmos_modulos_com_outros_valores" {
  command = apply

  variables {
    environment = "staging"
    vpc_cidr    = "10.1.0.0/16"
    db_name     = "technova_staging"
    subnets = {
      "public-1"  = { cidr = "10.1.1.0/24", az = "us-east-1a", type = "public" }
      "public-2"  = { cidr = "10.1.2.0/24", az = "us-east-1b", type = "public" }
      "private-1" = { cidr = "10.1.3.0/24", az = "us-east-1a", type = "private" }
      "private-2" = { cidr = "10.1.4.0/24", az = "us-east-1b", type = "private" }
    }
  }

  assert {
    condition     = output.db_name == "technova_staging"
    error_message = "O database do staging deve se chamar technova_staging."
  }

  assert {
    condition     = length(output.private_subnet_ids) == 2
    error_message = "Staging deve ter 2 subnets privadas."
  }
}
