variable "cluster_name" {
  type = string
}

variable "cluster_role_arn" {
  type = string
}

variable "node_role_arn" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "kubernetes_version" {
  type    = string
  default = "1.28.15"
}

variable "kms_key_arn" {
  type = string
}

variable "cluster_policy_attachments" {
  type    = list(string)
  default = []
}

variable "node_policy_attachments" {
  type    = list(string)
  default = []
}

variable "vpc_cni_version" {
  type    = string
  default = "v1.18.1-eksbuild.1"
}

variable "coredns_version" {
  type    = string
  default = "v1.10.1-eksbuild.7"
}

variable "kube_proxy_version" {
  type    = string
  default = "v1.28.8-eksbuild.5"
}

variable "ebs_csi_version" {
  type    = string
  default = "v1.30.0-eksbuild.1"
}

variable "vpc_cni_role_arn" {
  type = string
}

variable "ebs_csi_role_arn" {
  type = string
}

variable "ssh_key_name" {
  type    = string
  default = null
}

variable "public_access_cidrs" {
  description = "List of trusted CIDR blocks allowed to access the EKS API server public endpoint (e.g. office/VPN IPs)"
  type        = list(string)
  default     = ["203.0.113.0/24"]
}
