output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_cidr" {
  value = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_cluster_version" {
  value = module.eks.cluster_version
}

output "eks_cluster_security_group_id" {
  value = module.eks.cluster_security_group_id
}

output "eks_oidc_issuer_url" {
  value = module.eks.oidc_issuer_url
}

output "rds_endpoint" {
  value = module.rds.db_instance_endpoint
}

output "rds_port" {
  value = module.rds.db_instance_port
}

output "rds_database_name" {
  value = module.rds.db_name
}

output "rds_password_secret_arn" {
  value = module.rds.password_secret_arn
}

output "domain_zone_id" {
  value = data.aws_route53_zone.main.zone_id
}

output "ssl_certificate_arn" {
  value = aws_acm_certificate_validation.platform.certificate_arn
}

output "platform_urls" {
  value = {
    portal   = "https://portal.${var.domain_name}"
    api      = "https://api.${var.domain_name}"
    platform = "https://platform.${var.domain_name}"
  }
}

output "kubectl_config_command" {
  value = "aws eks --region ${var.aws_region} update-kubeconfig --name ${module.eks.cluster_name}"
}

output "prometheus_workspace_endpoint" {
  value = module.monitoring.prometheus_workspace_endpoint
}

output "prometheus_ingest_role_arn" {
  value = module.monitoring.prometheus_ingest_role_arn
}