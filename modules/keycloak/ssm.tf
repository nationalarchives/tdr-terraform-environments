resource "aws_ssm_parameter" "database_url" {
  name  = "/${var.environment}/keycloak/database/url"
  type  = "String"
  value = "jdbc:postgresql://${aws_rds_cluster.keycloak_database.endpoint}:${aws_rds_cluster.keycloak_database.port}/${aws_rds_cluster.keycloak_database.database_name}"
}

resource "aws_ssm_parameter" "database_username" {
  name  = "/${var.environment}/keycloak/database/username"
  type  = "String"
  value = aws_rds_cluster.keycloak_database.master_username
}

resource "aws_ssm_parameter" "database_password" {
  name  = "/${var.environment}/keycloak/database/password"
  type  = "String"
  value = aws_rds_cluster.keycloak_database.master_password
}
