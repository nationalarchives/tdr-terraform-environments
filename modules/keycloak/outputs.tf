output "auth_url" {
  value = "https://${aws_route53_record.keycloak_dns.name}.${trimsuffix(data.aws_route53_zone.keycloak_dns_zone.name, ".")}"
}