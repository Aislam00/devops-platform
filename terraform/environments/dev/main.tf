terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.15"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  backend "s3" {}
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

locals {
  cluster_name = "${var.project_name}-${var.environment}"
  account_id   = data.aws_caller_identity.current.account_id
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Owner       = var.owner
    ManagedBy   = "terraform"
  }
}

module "vpc" {
  source = "../../modules/vpc"

  vpc_name             = "${var.project_name}-${var.environment}"
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  cluster_name         = local.cluster_name
  tags                 = local.common_tags
}

module "iam" {
  source = "../../modules/iam"

  cluster_name       = local.cluster_name
  project_name       = var.project_name
  environment        = var.environment
  aws_region         = var.aws_region
  account_id         = local.account_id
  oidc_provider_arn  = aws_iam_openid_connect_provider.eks.arn
  oidc_issuer_url    = module.eks.oidc_issuer_url
  cluster_arn        = module.eks.cluster_arn
  tags               = local.common_tags

  depends_on = [module.eks]
}

module "eks" {
  source = "../../modules/eks"

  cluster_name       = local.cluster_name
  cluster_role_arn   = module.iam.eks_cluster_role_arn
  node_role_arn      = module.iam.eks_node_group_role_arn
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  kubernetes_version = var.kubernetes_version

  kms_key_arn = module.iam.eks_kms_key_arn

  cluster_policy_attachments = [
    module.iam.cluster_policy_attachment_id
  ]

  node_policy_attachments = module.iam.node_policy_attachment_ids

  vpc_cni_role_arn = module.iam.vpc_cni_role_arn
  ebs_csi_role_arn = module.iam.ebs_csi_role_arn

  depends_on = [
    module.vpc,
    module.iam
  ]
}

module "rds" {
  source = "../../modules/rds"

  db_name               = "${var.project_name}-${var.environment}-db"
  database_name         = var.database_name
  master_username       = var.db_master_username
  postgres_version      = var.postgres_version
  instance_class        = var.db_instance_class
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage

  vpc_id               = module.vpc.vpc_id
  vpc_cidr             = module.vpc.vpc_cidr_block
  private_subnet_ids   = module.vpc.private_subnet_ids
  db_subnet_group_name = "${var.project_name}-${var.environment}-db-subnet-group"

  backup_retention_period      = var.environment == "prod" ? 30 : 7
  skip_final_snapshot          = var.environment != "prod"
  deletion_protection          = var.environment == "prod"
  performance_insights_enabled = var.environment == "prod"

  depends_on = [module.vpc]
}

module "ecr" {
  source = "../../modules/ecr"

  project_name = var.project_name
  tags         = local.common_tags
}

module "secrets" {
  source = "../../modules/secrets"

  project_name         = var.project_name
  environment          = var.environment
  db_instance_endpoint = module.rds.db_instance_endpoint
  db_instance_port     = module.rds.db_instance_port
  db_name              = module.rds.db_name
  db_master_username   = module.rds.master_username
  db_password          = module.rds.db_password
  tags                 = local.common_tags

  depends_on = [module.rds]
}

module "route53" {
  source = "../../modules/route53"

  domain_name           = var.domain_name
  hosted_zone_id        = data.aws_route53_zone.main.zone_id
  api_alb_hostname      = var.api_dns_record
  portal_alb_hostname   = var.portal_dns_record
  grafana_alb_hostname  = var.grafana_dns_record
  prometheus_alb_hostname = var.prometheus_dns_record
  certificate_arn       = aws_acm_certificate_validation.platform.certificate_arn
  tags                  = local.common_tags
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

resource "aws_security_group_rule" "alb_https_inbound" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = module.eks.cluster_security_group_id
}

resource "aws_security_group_rule" "alb_http_inbound" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = module.eks.cluster_security_group_id
}
