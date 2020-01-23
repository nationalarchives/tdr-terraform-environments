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
