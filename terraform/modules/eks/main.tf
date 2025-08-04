resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = concat(var.public_subnet_ids, var.private_subnet_ids)
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  encryption_config {
    provider {
      key_arn = var.kms_key_arn
    }
    resources = ["secrets"]
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    var.cluster_policy_attachments
  ]

  tags = {
    Name = var.cluster_name
    Type = "platform-cluster"
  }
}

resource "aws_eks_node_group" "platform_services" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-platform-services"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids

  capacity_type  = "SPOT"
  instance_types = ["t3.medium", "t3a.medium"]

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  ami_type  = "AL2_x86_64"
  disk_size = 20

  labels = {
    role = "platform-services"
    tier = "system"
  }

  taint {
    key    = "platform-services"
    value  = "true"
    effect = "NO_SCHEDULE"
  }

  depends_on = [
    var.node_policy_attachments
  ]

  tags = {
    Name = "${var.cluster_name}-platform-services"
    Type = "platform-node-group"
  }
}

resource "aws_eks_node_group" "tenant_workloads" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-tenant-workloads"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids

  capacity_type  = "SPOT"
  instance_types = ["t3.small", "t3.medium", "t3a.small", "t3a.medium"]

  scaling_config {
    desired_size = 1
    max_size     = 6
    min_size     = 0
  }

  update_config {
    max_unavailable = 1
  }

  ami_type  = "AL2_x86_64"
  disk_size = 20

  labels = {
    role = "tenant-workloads"
    tier = "application"
  }

  depends_on = [
    var.node_policy_attachments
  ]

  tags = {
    Name = "${var.cluster_name}-tenant-workloads"
    Type = "tenant-node-group"
  }
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "vpc-cni"
  addon_version               = var.vpc_cni_version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  service_account_role_arn    = var.vpc_cni_role_arn

  depends_on = [aws_eks_node_group.platform_services]
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "coredns"
  addon_version               = var.coredns_version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.platform_services]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "kube-proxy"
  addon_version               = var.kube_proxy_version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.platform_services]
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "aws-ebs-csi-driver"
  addon_version               = var.ebs_csi_version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  service_account_role_arn    = var.ebs_csi_role_arn

  depends_on = [aws_eks_node_group.platform_services]
}