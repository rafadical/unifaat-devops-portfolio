variable "name" {
  description = "Sufixo do nome do Security Group (ex.: api, rds, bastion)."
  type        = string
}

variable "description" {
  description = "Descrição do Security Group."
  type        = string
  default     = "Managed by Terraform"
}

variable "vpc_id" {
  description = "ID da VPC onde o Security Group será criado."
  type        = string
}

variable "ingress_rules" {
  description = "Regras de entrada. Informe cidr_blocks, source_security_group_ids ou ambos."
  type = list(object({
    description               = string
    from_port                 = number
    to_port                   = number
    protocol                  = optional(string, "tcp")
    cidr_blocks               = optional(list(string), [])
    source_security_group_ids = optional(list(string), [])
  }))
  default = []

  validation {
    condition = alltrue([
      for r in var.ingress_rules : length(r.cidr_blocks) + length(r.source_security_group_ids) > 0
    ])
    error_message = "Cada regra precisa de pelo menos uma origem: cidr_blocks ou source_security_group_ids."
  }
}

variable "environment" {
  description = "Nome do ambiente (dev, staging, prod)."
  type        = string
}

variable "project_name" {
  description = "Nome do projeto, usado como prefixo do Security Group."
  type        = string
}

variable "tags" {
  description = "Tags adicionais."
  type        = map(string)
  default     = {}
}
