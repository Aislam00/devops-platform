resource "aws_db_subnet_group" "main" {
  name       = var.db_subnet_group_name
  subnet_ids = var.private_subnet_ids
  tags = {
    Name = var.db_subnet_group_name
  }
}

resource "aws_security_group" "rds" {
  name_prefix = "${var.db_name}-rds-"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name = "${var.db_name}-rds-sg"
  }
}

resource "aws_kms_key" "rds" {
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.db_name}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

data "aws_caller_identity" "current" {}

resource "random_password" "master" {
  length           = 32
  special          = true
  min_upper        = 4
  min_lower        = 4
  min_numeric      = 4
  min_special      = 4
  override_special = "!#$%&*()-_=+[]{}|;:,.<>?"
}

resource "aws_secretsmanager_secret" "rds_password" {
  name_prefix             = "${var.db_name}-master-password-"   
  recovery_window_in_days = 7
  kms_key_id              = aws_kms_key.rds.arn
}

resource "aws_secretsmanager_secret_version" "rds_password" {
  secret_id = aws_secretsmanager_secret.rds_password.id
  secret_string = jsonencode({
    username = var.master_username
    password = random_password.master.result
  })
}

resource "aws_db_parameter_group" "main" {
  family = "postgres15"
  name   = "${var.db_name}-params"

  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
  }
}

resource "aws_db_instance" "main" {
  identifier = var.db_name

  engine                = "postgres"
  engine_version        = var.postgres_version
  instance_class        = var.instance_class
  parameter_group_name  = aws_db_parameter_group.main.name

  allocated_storage                = var.allocated_storage
  max_allocated_storage           = var.max_allocated_storage
  storage_type                    = "gp3"
  storage_encrypted               = true
  kms_key_id                      = aws_kms_key.rds.arn
  publicly_accessible            = false
  multi_az                        = var.instance_class != "db.t3.micro"
  auto_minor_version_upgrade      = true
  allow_major_version_upgrade     = false

  db_name  = var.database_name
  username = var.master_username
  password = random_password.master.result

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = var.backup_retention_period
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"
  copy_tags_to_snapshot   = true

  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.db_name}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_kms_key_id       = var.performance_insights_enabled ? aws_kms_key.rds.arn : null
  performance_insights_retention_period = var.performance_insights_enabled ? 7 : null

  enabled_cloudwatch_logs_exports = ["postgresql"]

  deletion_protection = var.deletion_protection

  monitoring_interval = var.performance_insights_enabled ? 60 : 0
  monitoring_role_arn = var.performance_insights_enabled ? aws_iam_role.rds_enhanced_monitoring[0].arn : null

  tags = {
    Name = var.db_name
  }
}

resource "aws_iam_role" "rds_enhanced_monitoring" {
  count = var.performance_insights_enabled ? 1 : 0
  name  = "${var.db_name}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  count      = var.performance_insights_enabled ? 1 : 0
  role       = aws_iam_role.rds_enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
