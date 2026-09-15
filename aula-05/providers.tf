terraform {
  required_version = ">= 1.10, < 2.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    key     = "aula-05/6322006/terraform.tfstate"
    encrypt = true
    # bucket, region e dynamodb_table são fornecidos por backend.hcl.
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project   = "TechNova"
      Aula      = "05"
      RA        = "6322006"
      Aluno     = "rafael nogueira maruca"
      ManagedBy = "Terraform"
    }
  }
}
