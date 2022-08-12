//Delete this file once the DB move is complete
resource "aws_ssm_parameter" "database_url" {
  name  = "/${var.environment}/consignmentapi/database/url"
  type  = "SecureString"
  value = aws_rds_cluster.consignment_api_database.endpoint
}

resource "aws_ssm_parameter" "database_username" {
  name  = "/${var.environment}/consignmentapi/database/username"
  type  = "SecureString"
  value = aws_rds_cluster.consignment_api_database.master_username
}

resource "aws_ssm_parameter" "database_password" {
  name  = "/${var.environment}/consignmentapi/database/password"
  type  = "SecureString"
  value = aws_rds_cluster.consignment_api_database.master_password
}
