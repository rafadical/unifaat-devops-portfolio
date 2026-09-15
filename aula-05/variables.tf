variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "ssh_cidr" {
  description = "IPv4 público do aluno com máscara /32."
  type        = string
  validation {
    condition     = can(cidrnetmask(var.ssh_cidr)) && endswith(var.ssh_cidr, "/32")
    error_message = "Informe seu IPv4 público com /32 para limitar o SSH."
  }
}

variable "ssh_public_key_path" {
  description = "Caminho para a chave pública SSH .pub; nunca a chave privada."
  type        = string
}

variable "db_name" {
  type    = string
  default = "technova"
}

variable "db_username" {
  type    = string
  default = "technova_admin"
}

variable "db_password" {
  type      = string
  sensitive = true
  validation {
    condition     = length(var.db_password) >= 12 && length(var.db_password) <= 128 && can(regex("^[ -~]+$", var.db_password)) && !can(regex("[/@\" ]", var.db_password))
    error_message = "Use 12 a 128 caracteres ASCII imprimíveis, sem espaço, /, @ ou aspas duplas."
  }
}
