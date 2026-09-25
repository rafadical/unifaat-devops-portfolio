variable "aws_region" {
  description = "Região AWS usada para criar os recursos da TechNova"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "TechNova"
}

variable "environment" {
  description = "Ambiente de execução"
  type        = string
  default     = "dev"
}

variable "aluno" {
  description = "Nome do aluno"
  type        = string
  default     = "Rafael Nogueira Maruca"
}

variable "ra" {
  description = "Registro acadêmico do aluno"
  type        = string
  default     = "6322006"
}
