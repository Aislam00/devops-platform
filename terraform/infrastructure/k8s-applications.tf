resource "random_password" "jwt_secret" {
  length  = 32
  special = true
}

resource "random_password" "backstage_password" {
  length  = 16
  special = true
}

data "aws_secretsmanager_secret_version" "rds_password" {
  secret_id = module.rds.password_secret_arn
}

locals {
  rds_credentials = jsondecode(data.aws_secretsmanager_secret_version.rds_password.secret_string)
}

resource "kubernetes_namespace" "platform_api" {
  metadata {
    name = "platform-api"
    labels = {
      "pod-security.kubernetes.io/enforce" = "restricted"
      "pod-security.kubernetes.io/audit"   = "restricted"
      "pod-security.kubernetes.io/warn"    = "restricted"
    }
  }
}

resource "kubernetes_secret" "platform_api_secrets" {
  metadata {
    name      = "platform-api-secrets"
    namespace = kubernetes_namespace.platform_api.metadata[0].name
  }

  type = "Opaque"

  data = {
    DATABASE_URL = "postgres://${var.db_master_username}:${local.rds_credentials.password}@${module.rds.db_instance_endpoint}/${var.database_name}?sslmode=require"
    JWT_SECRET   = random_password.jwt_secret.result
  }
}

resource "kubernetes_service_account" "platform_api_sa" {
  metadata {
    name      = "platform-api-sa"
    namespace = kubernetes_namespace.platform_api.metadata[0].name
  }
}

resource "kubernetes_role" "platform_api_role" {
  metadata {
    name      = "platform-api-role"
    namespace = kubernetes_namespace.platform_api.metadata[0].name
  }

  rule {
    api_groups = [""]
    resources  = ["namespaces", "pods", "services"]
    verbs      = ["get", "list", "create", "delete"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments"]
    verbs      = ["get", "list"]
  }
}

resource "kubernetes_role_binding" "platform_api_binding" {
  metadata {
    name      = "platform-api-binding"
    namespace = kubernetes_namespace.platform_api.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.platform_api_role.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.platform_api_sa.metadata[0].name
    namespace = kubernetes_namespace.platform_api.metadata[0].name
  }
}

# resource "kubernetes_deployment" "platform_api" {
#   metadata {
#     name      = "platform-api"
#     namespace = kubernetes_namespace.platform_api.metadata[0].name
#   }
# 
#   spec {
#     replicas = 2
# 
#     selector {
#       match_labels = {
#         app = "platform-api"
#       }
#     }
# 
#     template {
#       metadata {
#         labels = {
#           app = "platform-api"
#         }
#       }
# 
#       spec {
#         service_account_name = kubernetes_service_account.platform_api_sa.metadata[0].name
# 
#         security_context {
#           run_as_non_root = true
#           run_as_user     = 65534
#           fs_group        = 65534
#           seccomp_profile {
#             type = "RuntimeDefault"
#           }
#         }
# 
#         toleration {
#           key      = "platform-services"
#           operator = "Equal"
#           value    = "true"
#           effect   = "NoSchedule"
#         }
# 
#         container {
#           name  = "platform-api"
#           image = "475641479654.dkr.ecr.eu-west-2.amazonaws.com/devplatform-api:latest"
# 
#           port {
#             container_port = 8080
#             protocol       = "TCP"
#           }
# 
#           security_context {
#             allow_privilege_escalation = false
#             read_only_root_filesystem  = true
#             run_as_non_root            = true
#             run_as_user                = 65534
#             capabilities {
#               drop = ["ALL"]
#             }
#           }
# 
#           env {
#             name = "DATABASE_URL"
#             value_from {
#               secret_key_ref {
#                 name = kubernetes_secret.platform_api_secrets.metadata[0].name
#                 key  = "DATABASE_URL"
#               }
#             }
#           }
# 
#           env {
#             name = "JWT_SECRET"
#             value_from {
#               secret_key_ref {
#                 name = kubernetes_secret.platform_api_secrets.metadata[0].name
#                 key  = "JWT_SECRET"
#               }
#             }
#           }
# 
#           env {
#             name  = "AWS_REGION"
#             value = var.aws_region
#           }
# 
#           env {
#             name  = "ENVIRONMENT"
#             value = var.environment
#           }
# 
#           env {
#             name  = "CLUSTER_NAME"
#             value = module.eks.cluster_name
#           }
# 
#           env {
#             name  = "DOMAIN_NAME"
#             value = var.domain_name
#           }
# 
#           env {
#             name  = "PORT"
#             value = "8080"
#           }
# 
#           resources {
#             requests = {
#               memory = "256Mi"
#               cpu    = "100m"
#             }
#             limits = {
#               memory = "512Mi"
#               cpu    = "250m"
#             }
#           }
# 
#           liveness_probe {
#             http_get {
#               path = "/api/v1/health"
#               port = 8080
#             }
#             initial_delay_seconds = 30
#             period_seconds        = 10
#           }
# 
#           readiness_probe {
#             http_get {
#               path = "/api/v1/health"
#               port = 8080
#             }
#             initial_delay_seconds = 5
#             period_seconds        = 5
#           }
# 
#           volume_mount {
#             name       = "tmp"
#             mount_path = "/tmp"
#           }
#         }
# 
#         volume {
#           name = "tmp"
#           empty_dir {}
#         }
#       }
#     }
#   }
# }

resource "kubernetes_service" "platform_api_service" {
  metadata {
    name      = "platform-api-service"
    namespace = kubernetes_namespace.platform_api.metadata[0].name
  }

  spec {
    selector = {
      app = "platform-api"
    }

    port {
      port        = 80
      target_port = 8080
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_ingress_v1" "platform_api_ingress" {
  metadata {
    name      = "platform-api-ingress"
    namespace = kubernetes_namespace.platform_api.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"               = "alb"
      "alb.ingress.kubernetes.io/scheme"          = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"     = "ip"
      "alb.ingress.kubernetes.io/certificate-arn" = aws_acm_certificate_validation.platform.certificate_arn
      "alb.ingress.kubernetes.io/listen-ports"    = "[{\"HTTPS\": 443}]"
      "alb.ingress.kubernetes.io/ssl-redirect"    = "443"
    }
  }

  spec {
    rule {
      host = "api.${var.domain_name}"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.platform_api_service.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_namespace" "backstage" {
  metadata {
    name = "backstage"
    labels = {
      "pod-security.kubernetes.io/enforce" = "restricted"
      "pod-security.kubernetes.io/audit"   = "restricted"
      "pod-security.kubernetes.io/warn"    = "restricted"
    }
  }
}

resource "kubernetes_secret" "backstage_secrets" {
  metadata {
    name      = "backstage-secrets"
    namespace = kubernetes_namespace.backstage.metadata[0].name
  }

  type = "Opaque"

  data = {
    POSTGRES_USER     = "backstage"
    POSTGRES_PASSWORD = random_password.backstage_password.result
  }
}

resource "kubernetes_service_account" "backstage_sa" {
  metadata {
    name      = "backstage-sa"
    namespace = kubernetes_namespace.backstage.metadata[0].name
  }
}

resource "kubernetes_cluster_role" "backstage_role" {
  metadata {
    name = "backstage-role"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services", "configmaps"]
    verbs      = ["get", "list"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "replicasets"]
    verbs      = ["get", "list"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get", "list"]
  }
}

resource "kubernetes_cluster_role_binding" "backstage_binding" {
  metadata {
    name = "backstage-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.backstage_role.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.backstage_sa.metadata[0].name
    namespace = kubernetes_namespace.backstage.metadata[0].name
  }
}

# resource "kubernetes_deployment" "backstage" {
#   metadata {
#     name      = "backstage"
#     namespace = kubernetes_namespace.backstage.metadata[0].name
#   }
# 
#   spec {
#     replicas = 2
# 
#     selector {
#       match_labels = {
#         app = "backstage"
#       }
#     }
# 
#     template {
#       metadata {
#         labels = {
#           app = "backstage"
#         }
#       }
# 
#       spec {
#         service_account_name = kubernetes_service_account.backstage_sa.metadata[0].name
# 
#         security_context {
#           run_as_non_root = true
#           run_as_user     = 65534
#           fs_group        = 65534
#           seccomp_profile {
#             type = "RuntimeDefault"
#           }
#         }
# 
#         toleration {
#           key      = "platform-services"
#           operator = "Equal"
#           value    = "true"
#           effect   = "NoSchedule"
#         }
# 
#         container {
#           name  = "backstage"
#           image = "475641479654.dkr.ecr.eu-west-2.amazonaws.com/devplatform-portal:latest"
# 
#           port {
#             container_port = 7007
#             protocol       = "TCP"
#           }
# 
#           security_context {
#             allow_privilege_escalation = false
#             read_only_root_filesystem  = true
#             run_as_non_root            = true
#             run_as_user                = 65534
#             capabilities {
#               drop = ["ALL"]
#             }
#           }
# 
#           env {
#             name = "POSTGRES_USER"
#             value_from {
#               secret_key_ref {
#                 name = kubernetes_secret.backstage_secrets.metadata[0].name
#                 key  = "POSTGRES_USER"
#               }
#             }
#           }
# 
#           env {
#             name = "POSTGRES_PASSWORD"
#             value_from {
#               secret_key_ref {
#                 name = kubernetes_secret.backstage_secrets.metadata[0].name
#                 key  = "POSTGRES_PASSWORD"
#               }
#             }
#           }
# 
#           resources {
#             requests = {
#               memory = "512Mi"
#               cpu    = "200m"
#             }
#             limits = {
#               memory = "1Gi"
#               cpu    = "500m"
#             }
#           }
# 
#           liveness_probe {
#             http_get {
#               path = "/"
#               port = 7007
#             }
#             initial_delay_seconds = 60
#             period_seconds        = 10
#           }
# 
#           readiness_probe {
#             http_get {
#               path = "/"
#               port = 7007
#             }
#             initial_delay_seconds = 30
#             period_seconds        = 5
#           }
# 
#           volume_mount {
#             name       = "tmp"
#             mount_path = "/tmp"
#           }
#         }
# 
#         volume {
#           name = "tmp"
#           empty_dir {}
#         }
#       }
#     }
#   }
# }

resource "kubernetes_service" "backstage_service" {
  metadata {
    name      = "backstage-service"
    namespace = kubernetes_namespace.backstage.metadata[0].name
  }

  spec {
    selector = {
      app = "backstage"
    }

    port {
      port        = 80
      target_port = 7007
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_ingress_v1" "backstage_ingress" {
  metadata {
    name      = "backstage-ingress"
    namespace = kubernetes_namespace.backstage.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"               = "alb"
      "alb.ingress.kubernetes.io/scheme"          = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"     = "ip"
      "alb.ingress.kubernetes.io/certificate-arn" = aws_acm_certificate_validation.platform.certificate_arn
      "alb.ingress.kubernetes.io/listen-ports"    = "[{\"HTTPS\": 443}]"
      "alb.ingress.kubernetes.io/ssl-redirect"    = "443"
    }
  }

  spec {
    rule {
      host = "portal.${var.domain_name}"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.backstage_service.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}