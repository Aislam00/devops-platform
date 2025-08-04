variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_role_arn" {
  description = "ARN of the IAM role for the EKS cluster"
  type        = string
}

variable "node_role_arn" {
  description = "ARN of the IAM role for EKS node groups"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "kms_key_arn" {
  description = "ARN of KMS key for EKS encryption"
  type        = string
}

variable "cluster_policy_attachments" {
  description = "Policy attachments for cluster role"
  type        = list(string)
  default     = []
}

variable "node_policy_attachments" {
  description = "Policy attachments for node role"
  type        = list(string)
  default     = []
}

variable "vpc_cni_version" {
  description = "Version of VPC CNI addon"
  type        = string
  default     = "v1.15.1-eksbuild.1"
}

variable "coredns_version" {
  description = "Version of CoreDNS addon"
  type        = string
  default     = "v1.10.1-eksbuild.5"
}

variable "kube_proxy_version" {
  description = "Version of kube-proxy addon"
  type        = string
  default     = "v1.28.2-eksbuild.2"
}

variable "ebs_csi_version" {
  description = "Version of EBS CSI driver addon"
  type        = string
  default     = "v1.24.0-eksbuild.1"
}

variable "vpc_cni_role_arn" {
  description = "ARN of IAM role for VPC CNI addon"
  type        = string
}

variable "ebs_csi_role_arn" {
  description = "ARN of IAM role for EBS CSI driver addon"
  type        = string
}