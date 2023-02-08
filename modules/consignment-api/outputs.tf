output "alb_security_group_id" {
  value = aws_security_group.lb.id
}

output "api_url" {
  value = "https://${aws_route53_record.api_dns.name}.${var.dns_zone_name_trimmed}"
}

output "ecs_task_security_group_id" {
  value = aws_security_group.ecs_tasks.id
}
