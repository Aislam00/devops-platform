variable "aws_region" {
  description = "AWS region for resources"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the platform"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"
}

variable "database_name" {
  description = "Database name for RDS instance"
  type        = string
  default     = "platform"
}

variable "db_master_username" {
  description = "Master username for RDS instance"
  type        = string
  default     = "platformadmin"
}

variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "15.7"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Initial allocated storage for RDS"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Maximum allocated storage for RDS"
  type        = number
  default     = 100
}

# Route53 DNS Record Variables (for dynamic configuration)
variable "portal_dns_record" {
  description = "DNS record for portal service"
  type        = string
}

variable "api_dns_record" {
  description = "DNS record for API service"
  type        = string
}

variable "grafana_dns_record" {
  description = "DNS record for Grafana service"
  type        = string
}

variable "prometheus_dns_record" {
  description = "DNS record for Prometheus service"
  type        = string
}