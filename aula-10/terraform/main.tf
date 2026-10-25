locals {
  prefix = "technova-6322006-aula10"
}

data "aws_availability_zones" "available" {
  state = "available"
}

# ---------------------------------------------------------------------------
# Rede: VPC com uma subnet pública (a EC2 precisa de internet para o ECR)
# ---------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${local.prefix}-vpc" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags                    = { Name = "${local.prefix}-public" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${local.prefix}-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "${local.prefix}-public-routes" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ---------------------------------------------------------------------------
# Security Group da API
# ---------------------------------------------------------------------------
resource "aws_security_group" "technova_api" {
  name        = "${local.prefix}-api"
  description = "TechNova API: SSH para o deploy do CD e porta da aplicacao"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH para os runners do GitHub Actions (IPs variaveis)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }

  ingress {
    description = "TechNova API e health check"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.prefix}-api-sg" }
}

# ---------------------------------------------------------------------------
# Registry: repositório ECR que recebe as imagens do pipeline CD
# ---------------------------------------------------------------------------
resource "aws_ecr_repository" "technova_api" {
  name                 = "technova-api"
  image_tag_mutability = "MUTABLE" # a tag latest é sobrescrita a cada deploy
  force_delete         = true      # laboratório: permite destroy com imagens

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "technova_api" {
  repository = aws_ecr_repository.technova_api.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Mantem as 10 imagens mais recentes (rollback)"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}

# ---------------------------------------------------------------------------
# Servidor: EC2 com Docker e AWS CLI (login no ECR antes do pull)
# ---------------------------------------------------------------------------
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

resource "aws_key_pair" "deploy" {
  key_name   = "${local.prefix}-key"
  public_key = var.ssh_public_key
}

resource "aws_instance" "app" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.technova_api.id]
  key_name                    = aws_key_pair.deploy.key_name
  user_data                   = file("${path.module}/user-data.sh")
  user_data_replace_on_change = true

  metadata_options {
    http_tokens = "required" # IMDSv2
  }

  root_block_device {
    encrypted   = true
    volume_size = 8
    volume_type = "gp3"
  }

  depends_on = [aws_route_table_association.public]
  tags       = { Name = "${local.prefix}-ec2" }
}

# IP fixo: o Learner Lab desliga a EC2 ao fim da sessão e o IP público mudaria,
# quebrando o secret EC2_HOST. O Elastic IP mantém o mesmo endereço.
resource "aws_eip" "app" {
  instance = aws_instance.app.id
  domain   = "vpc"
  tags     = { Name = "${local.prefix}-eip" }
}
