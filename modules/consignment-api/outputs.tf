output "alb_security_group_id" {
  value = aws_security_group.lb.id
}

output "database_url" {
  value = aws_rds_cluster.consignment_api_database.endpoint
}

output "database_username" {
  value = aws_rds_cluster.consignment_api_database.master_username
}

output "database_password" {
  value     = aws_rds_cluster.consignment_api_database.master_password
  sensitive = true
}

output "api_url" {
  value = "https://${aws_route53_record.api_dns.name}.${var.dns_zone_name_trimmed}"
}

output "consignment_db_security_group_id" {
  value = aws_security_group.database.id
}

output "database_cluster_id" {
  value = aws_rds_cluster.consignment_api_database.cluster_resource_id
}

output "database_security_group" {
  value = aws_security_group.database.id
}

output "ecs_task_security_group_id" {
  value = aws_security_group.ecs_tasks.id
}
