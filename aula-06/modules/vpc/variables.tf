variable "vpc_cidr" {
  description = "Bloco CIDR da VPC (ex.: 10.0.0.0/16)."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr deve ser um CIDR IPv4 válido."
  }
}

variable "project_name" {
  description = "Nome do projeto, usado como prefixo dos recursos."
  type        = string
}

variable "environment" {
  description = "Nome do ambiente (dev, staging, prod)."
  type        = string
}

variable "subnets" {
  description = "Mapa de subnets: chave = nome lógico; cidr, az e type (public ou private)."
  type = map(object({
    cidr = string
    az   = string
    type = string
  }))

  validation {
    condition     = alltrue([for s in values(var.subnets) : contains(["public", "private"], s.type)])
    error_message = "O campo type de cada subnet deve ser \"public\" ou \"private\"."
  }
}

variable "tags" {
  description = "Tags adicionais aplicadas a todos os recursos do módulo."
  type        = map(string)
  default     = {}
}
