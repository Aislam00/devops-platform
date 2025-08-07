output "db_instance_endpoint" {
  value = aws_db_instance.main.endpoint
}

output "db_instance_port" {
  value = aws_db_instance.main.port
}

output "db_instance_id" {
  value = aws_db_instance.main.identifier
}

output "db_instance_arn" {
  value = aws_db_instance.main.arn
}

output "db_name" {
  value = aws_db_instance.main.db_name
}

output "master_username" {
  value     = aws_db_instance.main.username
  sensitive = true
}

output "password_secret_arn" {
  value = aws_secretsmanager_secret.rds_password.arn
}

output "security_group_id" {
  value = aws_security_group.rds.id
}

output "kms_key_arn" {
  value = aws_kms_key.rds.arn
}