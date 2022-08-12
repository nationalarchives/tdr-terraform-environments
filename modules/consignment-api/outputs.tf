output "alb_security_group_id" {
  value = aws_security_group.lb.id
}

output "api_url" {
  value = "https://${aws_route53_record.api_dns.name}.${var.dns_zone_name_trimmed}"
}

output "consignment_db_security_group_id" {
  value = aws_security_group.database.id
}

output "database_security_group" {
  value = aws_security_group.database.id
}

output "ecs_task_security_group_id" {
  value = aws_security_group.ecs_tasks.id
}
