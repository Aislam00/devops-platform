output "api_repository_url" {
  value = aws_ecr_repository.platform_api.repository_url
}

output "portal_repository_url" {
  value = aws_ecr_repository.platform_portal.repository_url
}

output "api_repository_name" {
  value = aws_ecr_repository.platform_api.name
}

output "portal_repository_name" {
  value = aws_ecr_repository.platform_portal.name
}
