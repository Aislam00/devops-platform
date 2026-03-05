resource "random_password" "jwt_secret" {
  length  = 64
  special = true
}

resource "aws_secretsmanager_secret" "jwt_secret" {
  name_prefix = "${var.project_name}-${var.environment}-jwt-secret-"
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "jwt_secret" {
  secret_id = aws_secretsmanager_secret.jwt_secret.id
  secret_string = jsonencode({
    JWT_SECRET = random_password.jwt_secret.result
  })
}

data "aws_secretsmanager_secret_version" "rds_password" {
  secret_id = var.rds_password_secret_arn
}

resource "aws_secretsmanager_secret" "database_connection" {
  name_prefix = "${var.project_name}-${var.environment}-database-connection-"
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "database_connection" {
  secret_id = aws_secretsmanager_secret.database_connection.id
  secret_string = jsonencode({
    DATABASE_URL      = "postgresql://${var.db_master_username}:${urlencode(data.aws_secretsmanager_secret_version.rds_password.secret_string)}@${split(":", var.db_instance_endpoint)[0]}:${var.db_instance_port}/${var.db_name}?sslmode=require"
    POSTGRES_HOST     = split(":", var.db_instance_endpoint)[0]
    POSTGRES_PORT     = tostring(var.db_instance_port)
    POSTGRES_DB       = var.db_name
    POSTGRES_USER     = var.db_master_username
    POSTGRES_PASSWORD = data.aws_secretsmanager_secret_version.rds_password.secret_string
    POSTGRES_SSL      = "require"
  })
}
