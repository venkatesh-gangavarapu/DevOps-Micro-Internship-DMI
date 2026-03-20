# ─────────────────────────────────────────────────────────
# main.tf — EpicBook AWS Infrastructure
# DevOps Micro Internship · Week 10 · Assignment 4
# Author: Venkatesh Gangavarapu
# ─────────────────────────────────────────────────────────

# ── Ubuntu 22.04 AMI (dynamic) ──────────────────────────
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ── VPC ─────────────────────────────────────────────────
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(var.tags, { Name = "epicbook-vpc" })
}

# ── Public Subnet (EC2) ──────────────────────────────────
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"
  tags = merge(var.tags, { Name = "epicbook-public" })
}

# ── Private Subnets (RDS — must span 2 AZs) ─────────────
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}a"
  tags = merge(var.tags, { Name = "epicbook-private-1" })
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.aws_region}b"
  tags = merge(var.tags, { Name = "epicbook-private-2" })
}

# ── Internet Gateway ─────────────────────────────────────
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.tags, { Name = "epicbook-igw" })
}

# ── Route Table (public subnet only) ────────────────────
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = merge(var.tags, { Name = "epicbook-public-rt" })
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ── EC2 Security Group ───────────────────────────────────
resource "aws_security_group" "ec2" {
  name        = "epicbook-ec2-sg"
  description = "EC2: Allow SSH + HTTP"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.tags, { Name = "epicbook-ec2-sg" })
}

# ── RDS Security Group (EC2 SG only — not public) ───────
resource "aws_security_group" "rds" {
  name        = "epicbook-rds-sg"
  description = "RDS: Allow MySQL from EC2 SG only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from EC2 only"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id] # SG reference — not CIDR
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.tags, { Name = "epicbook-rds-sg" })
}

# ── RDS Subnet Group (requires 2 AZs) ───────────────────
resource "aws_db_subnet_group" "main" {
  name       = "epicbook-db-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  tags       = merge(var.tags, { Name = "epicbook-db-subnet-group" })
}

# ── RDS MySQL Instance ───────────────────────────────────
resource "aws_db_instance" "mysql" {
  identifier             = "epicbook-mysql"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false  # Private — no public internet access
  skip_final_snapshot    = true   # Required for clean terraform destroy
  tags                   = merge(var.tags, { Name = "epicbook-mysql" })
}

# ── EC2 Instance ─────────────────────────────────────────
resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  associate_public_ip_address = true
  key_name                    = var.key_pair_name

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y && apt-get upgrade -y
    apt-get install -y nodejs npm git nginx mysql-client
    systemctl start nginx
    systemctl enable nginx
  EOF

  tags = merge(var.tags, { Name = "epicbook-ec2" })
}
