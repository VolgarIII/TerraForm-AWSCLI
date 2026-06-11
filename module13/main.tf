# -----------------------------------------------------------------------------
# SG ALB — public, accepte HTTPS depuis Internet
# -----------------------------------------------------------------------------
resource "aws_security_group" "alb" {
  name        = "formation-alb-sg"
  description = "SG public pour l ALB"
  vpc_id      = var.vpc_id

  tags = {
    Name = "formation-alb-sg"
    Tier = "alb"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from Internet"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_all" {
  security_group_id = aws_security_group.alb.id
  description       = "Egress all"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# -----------------------------------------------------------------------------
# SG Web — accepte HTTP depuis ALB
# -----------------------------------------------------------------------------
resource "aws_security_group" "web" {
  name        = "formation-web-sg"
  description = "SG pour les EC2 web derriere ALB"
  vpc_id      = var.vpc_id

  tags = {
    Name = "formation-web-sg"
    Tier = "web"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "web_http_from_alb" {
  security_group_id            = aws_security_group.web.id
  description                  = "HTTP from ALB"
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_egress_rule" "web_all" {
  security_group_id = aws_security_group.web.id
  description       = "Egress all"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# -----------------------------------------------------------------------------
# SG DB — accepte Postgres depuis web uniquement, pas d egress
# -----------------------------------------------------------------------------
resource "aws_security_group" "db" {
  name        = "formation-db-sg"
  description = "SG pour RDS Postgres, accessible depuis web uniquement"
  vpc_id      = var.vpc_id

  tags = {
    Name = "formation-db-sg"
    Tier = "db"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "db_postgres_from_web" {
  security_group_id            = aws_security_group.db.id
  description                  = "Postgres from web tier"
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.web.id
}
