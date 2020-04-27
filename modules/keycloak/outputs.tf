output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnets" {
  value = aws_subnet.public.*.id
}

output alb_security_group_id {
  value = aws_security_group.lb.id
}

output "auth_url" {
  value = "https://${aws_route53_record.keycloak_dns.name}.${var.dns_zone_name_trimmed}/auth"
}

output "client_secret_path" {
  value = aws_ssm_parameter.keycloak_client_secret.name
}