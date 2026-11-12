terraform {
  required_version = ">= 1.6, < 2.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # State local por ambiente (cada pasta tem o seu). Em equipe, trocar por
  # backend "s3" com key diferente por ambiente, como na aula 05.
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Aula        = "06"
      RA          = "6322006"
    }
  }
}
