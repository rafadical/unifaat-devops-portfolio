variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "ssh_public_key" {
  description = "Conteúdo da chave pública SSH (ssh-ed25519/ssh-rsa ...). No GitHub Actions vem do secret SSH_PUBLIC_KEY."
  type        = string
  validation {
    condition     = can(regex("^(ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp256) ", var.ssh_public_key))
    error_message = "Informe a chave PÚBLICA (.pub), nunca a privada."
  }
}

variable "ssh_cidr" {
  description = "Origem liberada na porta 22. Os runners do GitHub Actions usam IPs variáveis, por isso o padrão do lab é 0.0.0.0/0."
  type        = string
  default     = "0.0.0.0/0"
}

variable "app_port" {
  type    = number
  default = 3000
}
