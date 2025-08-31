output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "rds_endpoint" {
  value = module.rds.db_instance_endpoint
}

output "jwt_secret_name" {
  value = aws_secretsmanager_secret.jwt_secret.name
}

output "database_secret_name" {
  value = aws_secretsmanager_secret.database_connection.name
}

output "platform_api_role_arn" {
  value = aws_iam_role.platform_api.arn
}

output "backstage_role_arn" {
  value = aws_iam_role.backstage.arn
}

output "ecr_api_repository" {
  value = aws_ecr_repository.platform_api.repository_url
}

output "ecr_portal_repository" {
  value = aws_ecr_repository.platform_portal.repository_url
}

output "ssl_certificate_arn" {
  value = aws_acm_certificate_validation.platform.certificate_arn
}

output "platform_urls" {
  value = {
    portal = "https://portal.${var.domain_name}"
    api    = "https://api.${var.domain_name}"
  }
}
