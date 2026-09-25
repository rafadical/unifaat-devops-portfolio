variable "aws_region" {
  description = "Região AWS da TechNova"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "TechNova"
}

variable "environment" {
  description = "Ambiente"
  type        = string
  default     = "development"
}

variable "owner" {
  description = "RA do aluno"
  type        = string
  default     = "6322006"
}

variable "instance_type" {
  description = "Tipo da EC2"
  type        = string
  default     = "t2.micro"
}

variable "public_key" {
  description = "Chave SSH pública para o EC2"
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD2zOWnu1xg7m7gX7d7xwLzSxVQxXf2r7I5k4d2Qd7e9m6Fz/0x4w9M3M5wX9uD3QmC7S1Gr6b7n6NmWQGfQ1B6wT3i8Q7y4c9Wxu9qGoM9cQ8J1kO1oM1aVf7e7J1z0u1D0a3M2RJ7NQz0hUXv4L+UQCrqK7vX9TtZs1TQe7L5QX6QpL8u7gqH0GsuzVhB3hNkE7yYh7mW0+Q8w3QFQf0E2PJW0Q5CpmrVgQw5Bb4XqGxgF8uyhL0JFCsD3pY+36TQ2t8V1gV3/HeP1s2O7lRsuzwR1QfK8E2QdSRvWT9kQdQFXg7mNyG3vghr3UQ5Gorh0A5uCw2IY7b6krqvA4vK3QjvM/2r6u9dB7kZ2aL1qI=sample"
}

variable "vpc_cidr" {
  description = "CIDR da VPC"
  type        = string
  default     = "10.0.0.0/16"
}
