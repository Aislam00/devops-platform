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
  value = module.secrets.jwt_secret_name
}

output "database_secret_name" {
  value = module.secrets.database_secret_name
}

output "platform_api_role_arn" {
  value = module.iam.platform_api_role_arn
}

output "backstage_role_arn" {
  value = module.iam.backstage_role_arn
}

output "ecr_api_repository" {
  value = module.ecr.api_repository_url
}

output "ecr_portal_repository" {
  value = module.ecr.portal_repository_url
}

output "ssl_certificate_arn" {
  value = module.route53.certificate_arn
}

output "github_actions_role_arn" {
  value = module.github_oidc.role_arn
}

output "platform_urls" {
  value = {
    portal = "https://portal.${var.domain_name}"
    api    = "https://api.${var.domain_name}"
  }
}
