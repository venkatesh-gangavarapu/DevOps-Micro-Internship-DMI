# ── security-groups.tf ────────────────────────────────────
# 5 SGs: Public ALB, Web EC2, Internal ALB, App EC2, DB RDS

# ── Public ALB SG ─────────────────────────────────────────
resource "aws_security_group" "public_alb" {
  name   = "bookreview-public-alb-sg"
  vpc_id = aws_vpc.main.id
  ingress { from_port = 80;  to_port = 80;  protocol = "tcp"; cidr_blocks = ["0.0.0.0/0"] }
  egress  { from_port = 0;   to_port = 0;   protocol = "-1";  cidr_blocks = ["0.0.0.0/0"] }
  tags = merge(var.tags, { Name = "bookreview-public-alb-sg" })
}

# ── Web Tier EC2 SG ───────────────────────────────────────
resource "aws_security_group" "web_tier" {
  name   = "bookreview-web-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    description     = "HTTP from Public ALB only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.public_alb.id]
  }
  ingress { from_port = 22; to_port = 22; protocol = "tcp"; cidr_blocks = ["0.0.0.0/0"] }
  egress  { from_port = 0;  to_port = 0;  protocol = "-1";  cidr_blocks = ["0.0.0.0/0"] }
  tags = merge(var.tags, { Name = "bookreview-web-sg" })
}

# ── Internal ALB SG ───────────────────────────────────────
resource "aws_security_group" "internal_alb" {
  name   = "bookreview-internal-alb-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    description     = "API traffic from Web EC2 only"
    from_port       = 3001
    to_port         = 3001
    protocol        = "tcp"
    security_groups = [aws_security_group.web_tier.id]
  }
  egress { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }
  tags = merge(var.tags, { Name = "bookreview-internal-alb-sg" })
}

# ── App Tier EC2 SG ───────────────────────────────────────
resource "aws_security_group" "app_tier" {
  name   = "bookreview-app-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    description     = "Node.js from Internal ALB only"
    from_port       = 3001
    to_port         = 3001
    protocol        = "tcp"
    security_groups = [aws_security_group.internal_alb.id]
  }
  egress { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }
  tags = merge(var.tags, { Name = "bookreview-app-sg" })
}

# ── DB Tier RDS SG ────────────────────────────────────────
resource "aws_security_group" "db_tier" {
  name   = "bookreview-db-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    description     = "MySQL from App EC2 only"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_tier.id]
  }
  egress { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }
  tags = merge(var.tags, { Name = "bookreview-db-sg" })
}
