output "alb_security_group_id" {
  value = aws_security_group.lb.id
}

output "frontend_url" {
  value = "https://${var.dns_zone_name_trimmed}"
}

output "task_role_arn" {
  value = aws_iam_role.frontend_ecs_task.arn
}
