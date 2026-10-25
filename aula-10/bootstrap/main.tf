# Bootstrap do remote state da aula 10.
# Executado UMA vez, localmente, antes do GitOps: configura o bucket S3 e cria a
# tabela DynamoDB usados pelo backend de aula-10/terraform. Fica fora do fluxo
# plan/apply do GitHub Actions porque o backend precisa existir antes do init.
#
# O bucket em si é criado por bootstrap.sh (AWS CLI): o recurso aws_s3_bucket
# consulta Object Lock, operação negada pelo SCP do Learner Lab.

terraform {
  required_version = ">= 1.7, < 2.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project   = "TechNova"
      Aula      = "10"
      RA        = "6322006"
      Aluno     = "rafael nogueira maruca"
      ManagedBy = "Terraform"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  bucket_name = "6322006-technova-aula10-tfstate-${data.aws_caller_identity.current.account_id}"
  lock_table  = "6322006-technova-aula10-locks"
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = local.bucket_name
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = local.bucket_name
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = local.bucket_name
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "locks" {
  name         = local.lock_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}

output "state_bucket" {
  description = "Valor para a variável TF_STATE_BUCKET do repositório no GitHub."
  value       = local.bucket_name
}

output "lock_table" {
  value = aws_dynamodb_table.locks.name
}
