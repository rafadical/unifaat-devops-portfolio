variable "aws_region" {
  description = "Região AWS (Learner Lab: us-east-1)."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto, prefixo de todos os recursos."
  type        = string
  default     = "technova"
}

variable "environment" {
  description = "Nome do ambiente."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR da VPC do ambiente."
  type        = string
}

variable "subnets" {
  description = "Subnets do ambiente (passadas ao módulo VPC)."
  type = map(object({
    cidr = string
    az   = string
    type = string
  }))
}

variable "instance_type" {
  description = "Tipo da EC2 da API."
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Key pair para SSH (no Learner Lab já existe a vockey)."
  type        = string
  default     = "vockey"
}

variable "ssh_cidr" {
  description = "Origem permitida na porta 22 (seu IP com /32)."
  type        = string
  default     = "0.0.0.0/0"
}

variable "db_name" {
  description = "Nome do database do ambiente."
  type        = string
}

variable "db_username" {
  description = "Usuário master do PostgreSQL."
  type        = string
  default     = "technova_admin"
}

variable "db_password" {
  description = "Senha master do PostgreSQL. Informe via TF_VAR_db_password; nunca no tfvars versionado."
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "Classe da instância RDS."
  type        = string
  default     = "db.t3.micro"
}
