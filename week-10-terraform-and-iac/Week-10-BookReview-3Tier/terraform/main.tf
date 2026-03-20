# ─────────────────────────────────────────────────────────
# main.tf — Book Review App · 3-Tier AWS Network
# DevOps Micro Internship · Week 10 · Assignment 5
# Author: Venkatesh Gangavarapu
# Designed with Claude Code as AI copilot
# ─────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" { region = var.aws_region }

# ── AMI ──────────────────────────────────────────────────
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter { name = "name"; values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"] }
  filter { name = "virtualization-type"; values = ["hvm"] }
}

# ── VPC ──────────────────────────────────────────────────
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(var.tags, { Name = "bookreview-vpc" })
}

# ── WEB TIER Subnets (Public) ─────────────────────────────
resource "aws_subnet" "web_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags = merge(var.tags, { Name = "bookreview-web-1", Tier = "web" })
}
resource "aws_subnet" "web_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true
  tags = merge(var.tags, { Name = "bookreview-web-2", Tier = "web" })
}

# ── APP TIER Subnets (Private) ────────────────────────────
resource "aws_subnet" "app_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.aws_region}a"
  tags = merge(var.tags, { Name = "bookreview-app-1", Tier = "app" })
}
resource "aws_subnet" "app_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "${var.aws_region}b"
  tags = merge(var.tags, { Name = "bookreview-app-2", Tier = "app" })
}

# ── DB TIER Subnets (Private) ─────────────────────────────
resource "aws_subnet" "db_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "${var.aws_region}a"
  tags = merge(var.tags, { Name = "bookreview-db-1", Tier = "db" })
}
resource "aws_subnet" "db_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = "${var.aws_region}b"
  tags = merge(var.tags, { Name = "bookreview-db-2", Tier = "db" })
}

# ── Internet Gateway ──────────────────────────────────────
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.tags, { Name = "bookreview-igw" })
}

# ── Route Table (Web tier → IGW) ──────────────────────────
resource "aws_route_table" "web" {
  vpc_id = aws_vpc.main.id
  route { cidr_block = "0.0.0.0/0"; gateway_id = aws_internet_gateway.igw.id }
  tags = merge(var.tags, { Name = "bookreview-web-rt" })
}
resource "aws_route_table_association" "web_1" {
  subnet_id      = aws_subnet.web_1.id
  route_table_id = aws_route_table.web.id
}
resource "aws_route_table_association" "web_2" {
  subnet_id      = aws_subnet.web_2.id
  route_table_id = aws_route_table.web.id
}
