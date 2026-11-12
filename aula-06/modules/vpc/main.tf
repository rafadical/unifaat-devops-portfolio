locals {
  prefix          = "${var.project_name}-${var.environment}"
  public_subnets  = { for k, s in var.subnets : k => s if s.type == "public" }
  private_subnets = { for k, s in var.subnets : k => s if s.type == "private" }
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(var.tags, { Name = "${local.prefix}-vpc" })
}

# Subnets criadas dinamicamente a partir do mapa var.subnets
resource "aws_subnet" "this" {
  for_each = var.subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = each.value.type == "public"

  tags = merge(var.tags, {
    Name = "${local.prefix}-${each.key}"
    Tier = each.value.type
  })
}

resource "aws_internet_gateway" "this" {
  count  = length(local.public_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${local.prefix}-igw" })
}

resource "aws_route_table" "public" {
  count  = length(local.public_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this[0].id
  }

  tags = merge(var.tags, { Name = "${local.prefix}-public-rt" })
}

resource "aws_route_table_association" "public" {
  for_each       = local.public_subnets
  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.public[0].id
}

# Subnets privadas: tabela própria, sem rota para a internet
resource "aws_route_table" "private" {
  count  = length(local.private_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${local.prefix}-private-rt" })
}

resource "aws_route_table_association" "private" {
  for_each       = local.private_subnets
  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.private[0].id
}
