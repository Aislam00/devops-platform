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

module "eks" {
  source = "../../modules/eks"

  cluster_name       = local.cluster_name
  cluster_role_arn   = aws_iam_role.eks_cluster.arn
  node_role_arn      = aws_iam_role.eks_node_group.arn
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  kubernetes_version = var.kubernetes_version

  kms_key_arn = aws_kms_key.eks.arn

  cluster_policy_attachments = [
    aws_iam_role_policy_attachment.eks_cluster_policy.id
  ]

  node_policy_attachments = [
    aws_iam_role_policy_attachment.eks_worker_node_policy.id,
    aws_iam_role_policy_attachment.eks_cni_policy.id,
    aws_iam_role_policy_attachment.eks_container_registry_policy.id
  ]

  vpc_cni_role_arn = aws_iam_role.vpc_cni.arn
  ebs_csi_role_arn = aws_iam_role.ebs_csi.arn

  depends_on = [
    module.vpc,
    aws_iam_role.eks_cluster,
    aws_iam_role.eks_node_group
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

module "monitoring" {
  source = "../../modules/monitoring"

  project_name      = var.project_name
  environment       = var.environment
  cluster_name      = local.cluster_name
  oidc_provider_arn = aws_iam_openid_connect_provider.eks.arn
  oidc_issuer       = replace(module.eks.oidc_issuer_url, "https://", "")
  aws_region        = var.aws_region
  domain_name       = var.domain_name
  certificate_arn   = aws_acm_certificate_validation.platform.certificate_arn
  tags              = local.common_tags

  depends_on = [
    module.eks,
    aws_iam_openid_connect_provider.eks
  ]
}

resource "random_password" "jwt_secret" {
  length  = 64
  special = true
}

resource "aws_secretsmanager_secret" "jwt_secret" {
  name_prefix = "${var.project_name}-${var.environment}-jwt-secret-"
}

resource "aws_secretsmanager_secret_version" "jwt_secret" {
  secret_id = aws_secretsmanager_secret.jwt_secret.id
  secret_string = jsonencode({
    JWT_SECRET = random_password.jwt_secret.result
  })
}

resource "aws_secretsmanager_secret" "database_connection" {
  name_prefix = "${var.project_name}-${var.environment}-database-connection-"
}

resource "aws_secretsmanager_secret_version" "database_connection" {
  secret_id = aws_secretsmanager_secret.database_connection.id
  secret_string = jsonencode({
    DATABASE_URL      = "postgresql://${module.rds.master_username}:${urlencode(module.rds.db_password)}@${split(":", module.rds.db_instance_endpoint)[0]}:${module.rds.db_instance_port}/${module.rds.db_name}?sslmode=require"
    POSTGRES_HOST     = split(":", module.rds.db_instance_endpoint)[0]
    POSTGRES_PORT     = tostring(module.rds.db_instance_port)
    POSTGRES_DB       = module.rds.db_name
    POSTGRES_USER     = module.rds.master_username
    POSTGRES_PASSWORD = module.rds.db_password
    POSTGRES_SSL      = "require"
  })
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
