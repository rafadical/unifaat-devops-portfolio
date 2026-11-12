data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

module "vpc" {
  source       = "../../modules/vpc"
  vpc_cidr     = var.vpc_cidr
  subnets      = var.subnets
  project_name = var.project_name
  environment  = var.environment
}

module "api_sg" {
  source       = "../../modules/security-group"
  name         = "api"
  description  = "TechNova API: HTTP da aplicacao e SSH restrito"
  vpc_id       = module.vpc.vpc_id # composição: VPC → SG
  project_name = var.project_name
  environment  = var.environment

  ingress_rules = [
    {
      description = "API TechNova"
      from_port   = 3000
      to_port     = 3000
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "SSH administrativo"
      from_port   = 22
      to_port     = 22
      cidr_blocks = [var.ssh_cidr]
    },
  ]
}

module "rds_sg" {
  source       = "../../modules/security-group"
  name         = "rds"
  description  = "PostgreSQL acessivel apenas pela API"
  vpc_id       = module.vpc.vpc_id
  project_name = var.project_name
  environment  = var.environment

  ingress_rules = [
    {
      description               = "PostgreSQL vindo do SG da API"
      from_port                 = 5432
      to_port                   = 5432
      source_security_group_ids = [module.api_sg.sg_id] # composição: SG → SG
    },
  ]
}

module "api_server" {
  source             = "../../modules/ec2"
  instance_name      = "${var.project_name}-${var.environment}-api"
  instance_type      = var.instance_type
  ami_id             = data.aws_ami.al2023.id
  subnet_id          = module.vpc.public_subnet_ids[0] # composição: VPC → EC2
  security_group_ids = [module.api_sg.sg_id]           # composição: SG → EC2
  key_name           = var.key_name
  user_data          = <<-EOT
    #!/bin/bash
    dnf install -y postgresql15
  EOT
}

module "database" {
  source             = "../../modules/rds"
  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password
  instance_class     = var.db_instance_class
  subnet_ids         = module.vpc.private_subnet_ids # composição: VPC → RDS
  security_group_ids = [module.rds_sg.sg_id]         # composição: SG → RDS
  project_name       = var.project_name
  environment        = var.environment
}
