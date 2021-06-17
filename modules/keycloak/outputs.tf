output "vpc_id" {
  value = aws_vpc.main.id
}

output "vpc_cidr_block" {
  value = aws_vpc.main.cidr_block
}

output "public_subnets" {
  value = aws_subnet.public.*.id
}

output "private_subnets" {
  value = aws_subnet.private.*.id
}

output alb_security_group_id {
  value = aws_security_group.lb.id
}

output "auth_host" {
  value = "${aws_route53_record.keycloak_dns.name}.${var.dns_zone_name_trimmed}"
}

output "auth_url" {
  value = "https://${aws_route53_record.keycloak_dns.name}.${var.dns_zone_name_trimmed}/auth"
}

output "client_secret_path" {
  value = aws_ssm_parameter.keycloak_client_secret.name
}

output "backend_checks_client_secret_path" {
  value = aws_ssm_parameter.keycloak_backend_checks_client_secret.name
}

output "backend_checks_client_secret" {
  value = aws_ssm_parameter.keycloak_backend_checks_client_secret.value
}

output "db_username" {
  value = aws_rds_cluster.keycloak_database.master_username
}

output "db_password" {
  value = aws_rds_cluster.keycloak_database.master_password
}

output "db_url" {
  value = aws_rds_cluster.keycloak_database.endpoint
}

output "keycloak_user_password" {
  value = random_password.keycloak_password.result
}

output "database_security_group" {
  value = aws_security_group.database.id
}
