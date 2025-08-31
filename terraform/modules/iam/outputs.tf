output "eks_cluster_role_arn" {
  value = aws_iam_role.eks_cluster.arn
}

output "eks_node_group_role_arn" {
  value = aws_iam_role.eks_node_group.arn
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.eks.arn
}

output "vpc_cni_role_arn" {
  value = aws_iam_role.vpc_cni.arn
}

output "ebs_csi_role_arn" {
  value = aws_iam_role.ebs_csi.arn
}

output "platform_api_role_arn" {
  value = aws_iam_role.platform_api.arn
}

output "backstage_role_arn" {
  value = aws_iam_role.backstage.arn
}

output "aws_load_balancer_controller_role_arn" {
  value = aws_iam_role.aws_load_balancer_controller.arn
}

output "eks_kms_key_arn" {
  value = aws_kms_key.eks.arn
}

output "cluster_policy_attachment_id" {
  value = aws_iam_role_policy_attachment.eks_cluster_policy.id
}

output "node_policy_attachment_ids" {
  value = [
    aws_iam_role_policy_attachment.eks_worker_node_policy.id,
    aws_iam_role_policy_attachment.eks_cni_policy.id,
    aws_iam_role_policy_attachment.eks_container_registry_policy.id
  ]
}
