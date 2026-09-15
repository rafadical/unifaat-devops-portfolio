data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "student" {
  key_name   = "${local.prefix}-key"
  public_key = file(pathexpand(var.ssh_public_key_path))
  tags       = { Name = "${local.prefix}-key" }
}

resource "aws_security_group" "ec2" {
  name   = "${local.prefix}-ec2"
  vpc_id = aws_vpc.main.id
  ingress {
    description = "SSH apenas do aluno"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }
  ingress {
    description = "Porta da API conforme enunciado"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${local.prefix}-ec2-sg" }
}

resource "aws_instance" "app" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  key_name                    = aws_key_pair.student.key_name
  user_data                   = file("${path.module}/user-data.sh")
  user_data_replace_on_change = true
  metadata_options {
    http_tokens = "required"
  }
  root_block_device {
    encrypted   = true
    volume_size = 8
    volume_type = "gp3"
    tags        = { Name = "${local.prefix}-root", Project = "TechNova", Aula = "05" }
  }
  depends_on = [aws_route_table_association.public]
  tags       = { Name = "${local.prefix}-ec2" }
}
