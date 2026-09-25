locals {
  common_tags = {
    Project    = var.project_name
    ManagedBy  = "Terraform"
    Aluno      = var.aluno
    RA         = var.ra
    Disciplina = "DevOps - UniFAAT 2026-2"
    Aula       = "03"
    Environment = var.environment
  }
}

resource "aws_iam_group" "developers" {
  name = "SEURA-technova-developers"
  path = "/technova/"
}

resource "aws_iam_group" "platform_eng" {
  name = "SEURA-technova-platform-eng"
  path = "/technova/"
}

resource "aws_iam_user" "juliana_dev" {
  name = "SEURA-juliana-dev"
  path = "/technova/"
  tags = merge(local.common_tags, {
    Purpose = "Developer"
  })
}

resource "aws_iam_user" "rafael_platform" {
  name = "SEURA-rafael-platform"
  path = "/technova/"
  tags = merge(local.common_tags, {
    Purpose = "Platform Engineer"
  })
}

resource "aws_iam_user" "lucas_intern" {
  name = "SEURA-lucas-intern"
  path = "/technova/"
  tags = merge(local.common_tags, {
    Purpose = "Intern"
  })
}

resource "aws_iam_user_group_membership" "juliana_dev" {
  user = aws_iam_user.juliana_dev.name
  groups = [aws_iam_group.developers.name]
}

resource "aws_iam_user_group_membership" "rafael_platform" {
  user = aws_iam_user.rafael_platform.name
  groups = [
    aws_iam_group.developers.name,
    aws_iam_group.platform_eng.name,
  ]
}

resource "aws_iam_user_group_membership" "lucas_intern" {
  user = aws_iam_user.lucas_intern.name
  groups = [aws_iam_group.developers.name]
}
