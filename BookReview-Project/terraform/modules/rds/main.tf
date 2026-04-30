resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-aurora-subnet-group"
  subnet_ids = var.subnet_ids
  tags       = merge(var.tags, { Name = "${var.name}-aurora-subnet-group" })
}

resource "aws_security_group" "rds" {
  name        = "${var.name}-rds-sg"
  description = "Allow MySQL traffic from EKS nodes only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL from EKS nodes"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.eks_node_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-rds-sg" })
}

resource "aws_rds_cluster" "this" {
  cluster_identifier        = "${var.name}-aurora-cluster"
  engine                    = "aurora-mysql"
  engine_version            = "8.0.mysql_aurora.3.04.0"
  database_name             = var.db_name
  master_username           = var.db_username
  master_password           = var.db_password
  db_subnet_group_name      = aws_db_subnet_group.this.name
  vpc_security_group_ids    = [aws_security_group.rds.id]
  storage_encrypted         = true
  backup_retention_period   = 7
  preferred_backup_window   = "02:00-03:00"
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.name}-final-snapshot"
  deletion_protection       = false
  tags                      = var.tags
}

resource "aws_rds_cluster_instance" "this" {
  count              = 2
  identifier         = "${var.name}-aurora-instance-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.this.id
  instance_class     = "db.t3.medium"
  engine             = aws_rds_cluster.this.engine
  engine_version     = aws_rds_cluster.this.engine_version
  publicly_accessible = false
  tags               = var.tags
}
