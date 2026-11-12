variable "instance_name" {
  description = "Valor da tag Name da instância."
  type        = string
}

variable "instance_type" {
  description = "Tipo da instância EC2."
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "ID da AMI."
  type        = string
}

variable "subnet_id" {
  description = "ID da subnet onde a instância será criada."
  type        = string
}

variable "security_group_ids" {
  description = "Lista de IDs de Security Groups associados à instância."
  type        = list(string)
}

variable "key_name" {
  description = "Nome do key pair para SSH (no Learner Lab: vockey). null = sem chave."
  type        = string
  default     = null
}

variable "user_data" {
  description = "Script de inicialização opcional (cloud-init)."
  type        = string
  default     = null
}

variable "associate_public_ip" {
  description = "Associa IP público (true para subnet pública)."
  type        = bool
  default     = true
}

variable "root_volume_size" {
  description = "Tamanho do disco raiz em GB."
  type        = number
  default     = 8
}

variable "tags" {
  description = "Tags adicionais."
  type        = map(string)
  default     = {}
}
