resource "aws_security_group" "this" {
  name        = "${var.project_name}-${var.environment}-${var.name}"
  description = var.description
  vpc_id      = var.vpc_id

  # Cada objeto da lista vira uma regra; origem por CIDR e/ou por outro SG
  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      description     = ingress.value.description
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      cidr_blocks     = ingress.value.cidr_blocks
      security_groups = ingress.value.source_security_group_ids
    }
  }

  egress {
    description = "Todo trafego de saida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.project_name}-${var.environment}-${var.name}" })

  lifecycle {
    create_before_destroy = true
  }
}
