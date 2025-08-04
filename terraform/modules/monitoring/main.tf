resource "aws_prometheus_workspace" "main" {
  alias = "${var.project_name}-${var.environment}-prometheus"
  tags  = var.tags
}

data "aws_iam_policy_document" "prometheus_ingest_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${var.oidc_issuer}:sub"
      values   = ["system:serviceaccount:prometheus:prometheus-server"]
    }
    condition {
      test     = "StringEquals"
      variable = "${var.oidc_issuer}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "prometheus_ingest" {
  name               = "${var.project_name}-${var.environment}-prometheus-ingest"
  assume_role_policy = data.aws_iam_policy_document.prometheus_ingest_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "prometheus_ingest" {
  role       = aws_iam_role.prometheus_ingest.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonPrometheusRemoteWriteAccess"
}

resource "kubernetes_namespace" "prometheus" {
  metadata {
    name = "prometheus"
  }
}

resource "kubernetes_service_account" "prometheus_server" {
  metadata {
    name      = "prometheus-server"
    namespace = kubernetes_namespace.prometheus.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.prometheus_ingest.arn
    }
  }
}

resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  namespace  = kubernetes_namespace.prometheus.metadata[0].name
  version    = "25.6.0"

  set {
    name  = "serviceAccounts.server.name"
    value = kubernetes_service_account.prometheus_server.metadata[0].name
  }

  set {
    name  = "serviceAccounts.server.create"
    value = "false"
  }

  set {
    name  = "server.remoteWrite[0].url"
    value = "${aws_prometheus_workspace.main.prometheus_endpoint}api/v1/remote_write"
  }

  set {
    name  = "server.remoteWrite[0].sigv4.region"
    value = var.aws_region
  }

  set {
    name  = "server.persistentVolume.enabled"
    value = "false"
  }

  set {
    name  = "alertmanager.enabled"
    value = "false"
  }

  set {
    name  = "prometheus-pushgateway.enabled"
    value = "false"
  }

  values = [
    yamlencode({
      server = {
        tolerations = [
          {
            key      = "platform-services"
            operator = "Equal"
            value    = "true"
            effect   = "NoSchedule"
          }
        ]
      }
      kube-state-metrics = {
        tolerations = [
          {
            key      = "platform-services"
            operator = "Equal"
            value    = "true"
            effect   = "NoSchedule"
          }
        ]
      }
    })
  ]

  depends_on = [
    aws_prometheus_workspace.main,
    kubernetes_service_account.prometheus_server
  ]
}

resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  namespace  = kubernetes_namespace.prometheus.metadata[0].name
  version    = "8.5.0"

  set {
    name  = "persistence.enabled"
    value = "false"
  }

  set {
    name  = "adminPassword"
    value = "admin123"
  }

  values = [
    yamlencode({
      tolerations = [
        {
          key      = "platform-services"
          operator = "Equal"
          value    = "true"
          effect   = "NoSchedule"
        }
      ]
      datasources = {
        "datasources.yaml" = {
          apiVersion = 1
          datasources = [
            {
              name      = "Prometheus"
              type      = "prometheus"
              url       = "http://prometheus-server:80"
              access    = "proxy"
              isDefault = true
            }
          ]
        }
      }
    })
  ]

  depends_on = [helm_release.prometheus]
}

resource "kubernetes_ingress_v1" "grafana" {
  metadata {
    name      = "grafana-ingress"
    namespace = kubernetes_namespace.prometheus.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"               = "alb"
      "alb.ingress.kubernetes.io/scheme"          = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"     = "ip"
      "alb.ingress.kubernetes.io/certificate-arn" = "arn:aws:acm:eu-west-2:475641479654:certificate/8376e6c1-8fab-4fc7-bca0-1f48098dcb1d"
      "alb.ingress.kubernetes.io/listen-ports"    = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
      "alb.ingress.kubernetes.io/ssl-redirect"    = "443"
    }
  }

  spec {
    rule {
      host = "grafana.${var.domain_name}"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "grafana"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.grafana]
}

resource "kubernetes_ingress_v1" "prometheus" {
  metadata {
    name      = "prometheus-ingress"
    namespace = kubernetes_namespace.prometheus.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"               = "alb"
      "alb.ingress.kubernetes.io/scheme"          = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"     = "ip"
      "alb.ingress.kubernetes.io/certificate-arn" = "arn:aws:acm:eu-west-2:475641479654:certificate/8376e6c1-8fab-4fc7-bca0-1f48098dcb1d"
      "alb.ingress.kubernetes.io/listen-ports"    = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
      "alb.ingress.kubernetes.io/ssl-redirect"    = "443"
    }
  }

  spec {
    rule {
      host = "prometheus.${var.domain_name}"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "prometheus-server"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.prometheus]
}