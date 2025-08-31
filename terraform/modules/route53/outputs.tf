output "certificate_arn" {
  value = aws_acm_certificate_validation.platform.certificate_arn
}

output "platform_certificate_arn" {
  value = aws_acm_certificate.platform.arn
}

output "api_record_fqdn" {
  value = aws_route53_record.api.fqdn
}

output "portal_record_fqdn" {
  value = aws_route53_record.portal.fqdn
}
