terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.1"
    }
  }

  backend "s3" {
    bucket         = "devplatform-terraform-state-475641479654"
    key            = "infrastructure/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "devplatform-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = "devplatform"
      Environment = var.environment
      Owner       = "alamin.islam"
      ManagedBy   = "terraform"
    }
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

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

data "aws_caller_identity" "current" {}

data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

locals {
  cluster_name = "${var.project_name}-${var.environment}"
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Cluster     = local.cluster_name
  }
}

module "vpc" {
  source = "../modules/vpc"

  vpc_name             = "${var.project_name}-${var.environment}"
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  cluster_name         = local.cluster_name
}

module "eks" {
  source = "../modules/eks"

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
  source = "../modules/rds"

  db_name               = "${var.project_name}-${var.environment}-db"
  database_name         = "platform"
  master_username       = var.db_master_username
  postgres_version      = var.postgres_version
  instance_class        = var.db_instance_class
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage

  vpc_id               = module.vpc.vpc_id
  vpc_cidr             = module.vpc.vpc_cidr_block
  private_subnet_ids   = module.vpc.public_subnet_ids
  db_subnet_group_name = "${var.project_name}-${var.environment}-db-subnet-group"

  backup_retention_period      = var.environment == "prod" ? 30 : 7
  skip_final_snapshot          = var.environment != "prod"
  deletion_protection          = var.environment == "prod"
  performance_insights_enabled = var.environment == "prod"

  depends_on = [module.vpc]
}

module "monitoring" {
  source = "../modules/monitoring"

  project_name      = var.project_name
  environment       = var.environment
  oidc_provider_arn = aws_iam_openid_connect_provider.eks.arn
  oidc_issuer       = replace(module.eks.oidc_issuer_url, "https://", "")
  aws_region        = var.aws_region
  domain_name       = var.domain_name

  tags = local.common_tags
}