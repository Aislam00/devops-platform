output "prometheus_workspace_id" {
  value = aws_prometheus_workspace.main.id
}

output "prometheus_workspace_endpoint" {
  value = aws_prometheus_workspace.main.prometheus_endpoint
}

output "prometheus_ingest_role_arn" {
  value = aws_iam_role.prometheus_ingest.arn
}

output "grafana_admin_password" {
  value     = random_password.grafana_admin.result
  sensitive = true
}