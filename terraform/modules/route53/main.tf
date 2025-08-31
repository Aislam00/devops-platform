resource "aws_acm_certificate" "platform" {
  domain_name = "platform.${var.domain_name}"
  subject_alternative_names = [
    "portal.${var.domain_name}",
    "api.${var.domain_name}",
    "grafana.${var.domain_name}",
    "prometheus.${var.domain_name}",
    "*.platform.${var.domain_name}"
  ]
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.platform.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.hosted_zone_id
}

resource "aws_acm_certificate_validation" "platform" {
  certificate_arn         = aws_acm_certificate.platform.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

  timeouts {
    create = "5m"
  }
}

resource "aws_route53_record" "portal" {
  zone_id = var.hosted_zone_id
  name    = "portal.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [var.portal_alb_hostname]
}

resource "aws_route53_record" "api" {
  zone_id = var.hosted_zone_id
  name    = "api.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [var.api_alb_hostname]
}

resource "aws_route53_record" "grafana" {
  count   = var.grafana_alb_hostname != null ? 1 : 0
  zone_id = var.hosted_zone_id
  name    = "grafana.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [var.grafana_alb_hostname]
}

resource "aws_route53_record" "prometheus" {
  count   = var.prometheus_alb_hostname != null ? 1 : 0
  zone_id = var.hosted_zone_id
  name    = "prometheus.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [var.prometheus_alb_hostname]
}
