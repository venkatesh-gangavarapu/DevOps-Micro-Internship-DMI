# ── rds.tf ───────────────────────────────────────────────

resource "aws_db_subnet_group" "main" {
  name       = "bookreview-db-subnet-group"
  subnet_ids = [aws_subnet.db_1.id, aws_subnet.db_2.id]
  tags       = merge(var.tags, { Name = "bookreview-db-subnet-group" })
}

# ── Primary RDS (Multi-AZ) ────────────────────────────────
resource "aws_db_instance" "primary" {
  identifier             = "bookreview-mysql"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "bookreview"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db_tier.id]
  multi_az               = true   # Auto failover to standby in AZ2
  publicly_accessible    = false
  skip_final_snapshot    = true
  backup_retention_period = 7     # 7-day automated backups
  tags = merge(var.tags, { Name = "bookreview-mysql-primary" })
}

# ── Read Replica ──────────────────────────────────────────
resource "aws_db_instance" "replica" {
  identifier          = "bookreview-mysql-replica"
  replicate_source_db = aws_db_instance.primary.id
  instance_class      = "db.t3.micro"
  publicly_accessible = false
  skip_final_snapshot = true
  tags = merge(var.tags, { Name = "bookreview-mysql-replica" })
}
