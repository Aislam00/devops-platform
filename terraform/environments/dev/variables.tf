variable "aws_region" {
  type = string
}

variable "environment" {
  type = string
}

variable "project_name" {
  type = string
}

variable "owner" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]
}

variable "allowed_cidr_blocks" {
  type    = list(string)
  default = ["10.0.0.0/16"]
}

variable "kubernetes_version" {
  type    = string
  default = "1.28.15"
}

variable "database_name" {
  type    = string
  default = "platform"
}

variable "db_master_username" {
  type    = string
  default = "platformadmin"
}

variable "postgres_version" {
  type    = string
  default = "15.7"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "db_max_allocated_storage" {
  type    = number
  default = 100
}

variable "github_repo" {
  description = "GitHub repository in owner/repo format for OIDC trust policy"
  type        = string
}

variable "portal_dns_record" {
  type    = string
  default = "portal-alb.eu-west-2.elb.amazonaws.com"
}

variable "api_dns_record" {
  type    = string
  default = "api-alb.eu-west-2.elb.amazonaws.com"
}

variable "grafana_dns_record" {
  type    = string
  default = "grafana-alb.eu-west-2.elb.amazonaws.com"
}

variable "prometheus_dns_record" {
  type    = string
  default = "prometheus-alb.eu-west-2.elb.amazonaws.com"
}
