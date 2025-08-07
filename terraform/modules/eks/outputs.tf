output "cluster_name" {
  value = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "cluster_security_group_id" {
  value = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "cluster_certificate_authority_data" {
  value = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_version" {
  value = aws_eks_cluster.main.version
}

output "cluster_arn" {
  value = aws_eks_cluster.main.arn
}

output "node_groups" {
  value = {
    platform_services = {
      arn           = aws_eks_node_group.platform_services.arn
      status        = aws_eks_node_group.platform_services.status
      capacity_type = aws_eks_node_group.platform_services.capacity_type
    }
    tenant_workloads = {
      arn           = aws_eks_node_group.tenant_workloads.arn
      status        = aws_eks_node_group.tenant_workloads.status
      capacity_type = aws_eks_node_group.tenant_workloads.capacity_type
    }
  }
}

output "oidc_issuer_url" {
  value = aws_eks_cluster.main.identity[0].oidc[0].issuer
}