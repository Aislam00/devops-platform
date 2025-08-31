output "jwt_secret_name" {
  value = aws_secretsmanager_secret.jwt_secret.name
}

output "database_secret_name" {
  value = aws_secretsmanager_secret.database_connection.name
}

output "jwt_secret_arn" {
  value = aws_secretsmanager_secret.jwt_secret.arn
}

output "database_secret_arn" {
  value = aws_secretsmanager_secret.database_connection.arn
}
