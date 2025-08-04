output "prometheus_workspace_id" {
  description = "Amazon Managed Prometheus workspace ID"
  value       = aws_prometheus_workspace.main.id
}

output "prometheus_workspace_endpoint" {
  description = "Amazon Managed Prometheus workspace endpoint"
  value       = aws_prometheus_workspace.main.prometheus_endpoint
}

output "prometheus_ingest_role_arn" {
  description = "IAM role ARN for Prometheus metrics ingestion"
  value       = aws_iam_role.prometheus_ingest.arn
}