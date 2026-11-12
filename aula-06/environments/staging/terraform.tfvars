# Valores do ambiente staging. Sem segredos: a senha do banco vem de TF_VAR_db_password.
environment = "staging"
vpc_cidr    = "10.1.0.0/16"
db_name     = "technova_staging"

subnets = {
  "public-1"  = { cidr = "10.1.1.0/24", az = "us-east-1a", type = "public" }
  "public-2"  = { cidr = "10.1.2.0/24", az = "us-east-1b", type = "public" }
  "private-1" = { cidr = "10.1.3.0/24", az = "us-east-1a", type = "private" }
  "private-2" = { cidr = "10.1.4.0/24", az = "us-east-1b", type = "private" }
}
