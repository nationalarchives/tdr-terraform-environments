output alb_security_group_id {
  value = aws_security_group.lb.id
}

output "auth_url" {
  value = "https://${aws_route53_record.keycloak_dns.name}.${var.dns_zone_name_trimmed}/auth"
}
