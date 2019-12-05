resource "random_password" "password" {
  length = 16
  special = true
  override_special = "_%@"
}


resource "aws_rds_cluster" "content_database" {
  cluster_identifier_prefix = "keycloak-db-${var.environment}"
  engine                    = "aurora-mysql"
  engine_mode		        = "serverless"
  availability_zones        = var.database_availability_zones
  database_name             = "keycloakdb"
  master_username           = "keycloak_admin"
  master_password           = random_password.password.result
  final_snapshot_identifier = "user-db-final-snapshot-${var.environment}"
  vpc_security_group_ids    = [var.security_group_ids]
  db_subnet_group_name      = var.subnet_group_name

  tags = merge(
    var.common_tags,
    map(
      "Name", "content-db-cluster-${var.environment}"
    )
  )

  lifecycle {
    ignore_changes = [
      # Ignore changes to availability zones because AWS automatically adds the
      # extra availability zone "eu-west-2c", which is rejected by the API as
      # unavailable if specified directly.
      availability_zones,
    ]
  }
}

resource "aws_rds_cluster_instance" "content_database" {
  count                = 1
  identifier_prefix    = "content-db-instance-${var.environment}"
  cluster_identifier   = aws_rds_cluster.content_database.id
  engine               = "aurora-mysql"
  instance_class       = "db.t3.medium"
  db_subnet_group_name = var.subnet_group_name
}

resource "aws_ssm_parameter" "database_url" {
  name  = "url"
  type  = "String"
  value = "jdbc:postgresql://${aws_rds_cluster.content_database.endpoint}:${aws_rds_cluster.content_database.port}/${aws_rds_cluster.content_database.database_name}"
}

resource "aws_ssm_parameter" "database_username" {
  name  = "/${var.environment}/keycloak/database/username"
  type  = "String"
  value = aws_rds_cluster.content_database.master_username
}

resource "aws_ssm_parameter" "database_password" {
  name  = "/${var.environment}/keycloak/database/password"
  type  = "String"
  value = aws_rds_cluster.content_database.master_password
}
