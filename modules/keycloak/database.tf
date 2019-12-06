resource "random_password" "password" {
  length = 16
  special = true
  override_special = "_%@"
}

resource "aws_db_subnet_group" "user_subnet_group" {
  name       = "main-${var.environment}"
  subnet_ids = aws_subnet.private.*.id

  tags = merge(
  var.common_tags,
  map(
  "Name", "user-db-subnet-group-${var.environment}"
  )
  )
}

resource "aws_rds_cluster" "keycloak_database" {
  cluster_identifier_prefix = "keycloak-db-${var.environment}"
  engine                    = "aurora"
  engine_mode		        = "serverless"
  engine_version            = "5.6.10a"
  availability_zones        = var.database_availability_zones
  database_name             = "keycloakdb"
  master_username           = "keycloak_admin"
  master_password           = random_password.password.result
  final_snapshot_identifier = "user-db-final-snapshot-${var.environment}"
  vpc_security_group_ids    = aws_security_group.database.*.id
  db_subnet_group_name      = aws_db_subnet_group.user_subnet_group.name

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

