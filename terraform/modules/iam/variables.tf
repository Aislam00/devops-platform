variable "cluster_name" {
  type = string
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "account_id" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "oidc_issuer_url" {
  type = string
}

variable "cluster_arn" {
  type = string
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for scoping EC2 security group operations"
}

variable "hosted_zone_id" {
  type        = string
  description = "Route53 hosted zone ID for scoping DNS record operations"
}

variable "tags" {
  type = map(string)
  default = {}
}
