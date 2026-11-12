variable "db_name" {
  description = "Nome do database inicial."
  type        = string
}

variable "db_username" {
  description = "Usuário master do PostgreSQL."
  type        = string
}

variable "db_password" {
  description = "Senha master (8 a 128 caracteres, sem /, @, aspas ou espaço)."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 8 && length(var.db_password) <= 128 && !can(regex("[/@\" ]", var.db_password))
    error_message = "A senha precisa de 8 a 128 caracteres e não pode conter /, @, aspas ou espaço."
  }
}

variable "subnet_ids" {
  description = "IDs das subnets privadas do DB Subnet Group (mínimo 2 AZs)."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "O RDS exige pelo menos 2 subnets em AZs diferentes."
  }
}

variable "security_group_ids" {
  description = "IDs dos Security Groups do RDS."
  type        = list(string)
}

variable "instance_class" {
  description = "Classe da instância RDS."
  type        = string
  default     = "db.t3.micro"
}

variable "engine_version" {
  description = "Versão do PostgreSQL."
  type        = string
  default     = "15"
}

variable "allocated_storage" {
  description = "Armazenamento em GB."
  type        = number
  default     = 20
}

variable "environment" {
  description = "Nome do ambiente (dev, staging, prod)."
  type        = string
}

variable "project_name" {
  description = "Nome do projeto, usado como prefixo."
  type        = string
}

variable "tags" {
  description = "Tags adicionais."
  type        = map(string)
  default     = {}
}
