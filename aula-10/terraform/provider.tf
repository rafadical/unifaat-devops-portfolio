terraform {
  required_version = ">= 1.7, < 2.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    key            = "aula-10/6322006/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "6322006-technova-aula10-locks"
    encrypt        = true
    # bucket é passado no init: -backend-config="bucket=<saída do bootstrap>"
  }
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
