# AWS Configuration
aws_region   = "eu-west-2"
project_name = "devplatform"
environment  = "dev"
owner        = "alamin.islam"

# Domain Configuration
domain_name = "iasolutions.co.uk"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"

# EKS Configuration
kubernetes_version = "1.28"

# Database Configuration
database_name = "platform"

# DNS Records (Load Balancer URLs)
portal_dns_record     = "k8s-backstag-backstag-a090799fb8-659957323.eu-west-2.elb.amazonaws.com"
api_dns_record        = "k8s-platform-platform-44b9e3bb8e-563398115.eu-west-2.elb.amazonaws.com"
grafana_dns_record    = "k8s-promethe-grafanai-46e46fdf83-1277684893.eu-west-2.elb.amazonaws.com"
prometheus_dns_record = "k8s-promethe-promethe-3945819cda-941519219.eu-west-2.elb.amazonaws.com"