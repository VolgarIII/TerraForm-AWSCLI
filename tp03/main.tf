# =============================================================================
# AMI — Amazon Linux 2023 (dernière version officielle)
# =============================================================================
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# =============================================================================
# Key Pair SSH
# =============================================================================
resource "aws_key_pair" "deployer" {
  key_name   = "${local.name_prefix}-key"
  public_key = file(pathexpand(var.public_key_path))

  tags = {
    Name  = "${local.name_prefix}-key"
    Owner = "etudiant09"
  }
}

# =============================================================================
# Security Group — serveurs web (accès SSH depuis bastion + HTTP ouvert)
# =============================================================================
resource "aws_security_group" "web" {
  name        = "${local.name_prefix}-web-sg"
  description = "SG des instances web en subnet prive"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-web-sg"
    Tier = "web"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "web_ssh_from_bastion" {
  security_group_id            = aws_security_group.web.id
  description                  = "SSH depuis le bastion"
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.formation_bastion_sg.id
}

resource "aws_vpc_security_group_ingress_rule" "web_http" {
  security_group_id = aws_security_group.web.id
  description       = "HTTP depuis Internet"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "web_all" {
  security_group_id = aws_security_group.web.id
  description       = "Egress all"
  from_port         = -1
  to_port           = -1
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# =============================================================================
# Bastion — EC2 public + EIP
# =============================================================================
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public[var.azs[0]].id
  vpc_security_group_ids = [aws_security_group.formation_bastion_sg.id]
  key_name               = aws_key_pair.deployer.key_name

  tags = {
    Name  = "${local.name_prefix}-bastion"
    Role  = "bastion"
    Owner = "etudiant09"
  }
}

resource "aws_eip" "bastion" {
  instance = aws_instance.bastion.id
  domain   = "vpc"

  tags = {
    Name = "${local.name_prefix}-bastion-eip"
  }
}

# =============================================================================
# Web EC2 — une instance par AZ (subnets privés)
# =============================================================================
resource "aws_instance" "web" {
  for_each = local.web_subnets

  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = each.value
  vpc_security_group_ids      = [aws_security_group.web.id]
  key_name                    = aws_key_pair.deployer.key_name
  user_data_replace_on_change = true

  user_data = templatefile("${path.module}/templates/nginx.sh.tftpl", {
    instance_id       = "web-${each.key}"
    availability_zone = each.key
    environment       = var.environment
  })

  tags = {
    Name  = "${local.name_prefix}-web-${each.key}"
    Role  = "web"
    AZ    = each.key
    Owner = "etudiant09"
  }

  lifecycle {
    create_before_destroy = true
  }
}
