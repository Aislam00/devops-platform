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
  default = "1.28"
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
  default = "v1.15.1-eksbuild.1"
}

variable "coredns_version" {
  type    = string
  default = "v1.10.1-eksbuild.5"
}

variable "kube_proxy_version" {
  type    = string
  default = "v1.28.2-eksbuild.2"
}

variable "ebs_csi_version" {
  type    = string
  default = "v1.24.0-eksbuild.1"
}

variable "vpc_cni_role_arn" {
  type = string
}

variable "ebs_csi_role_arn" {
  type = string
}