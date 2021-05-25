resource "random_password" "password" {
  length  = 41
  special = false
}

resource "aws_db_subnet_group" "consignment_api_subnet_group" {
  name       = "tdr-${var.environment}"
  subnet_ids = var.private_subnets

  tags = merge(
    var.common_tags,
    map(
      "Name", "user-db-subnet-group-${var.environment}"
    )
  )
}

resource "random_string" "snapshot_prefix" {
  length  = 4
  upper   = false
  special = false
}

resource "aws_rds_cluster" "consignment_api_database" {
  cluster_identifier_prefix           = "consignment-api-db-postgres-${var.environment}"
  engine                              = "aurora-postgresql"
  engine_version                      = "11.9"
  availability_zones                  = var.database_availability_zones
  database_name                       = var.app_name
  master_username                     = "api_admin"
  master_password                     = random_password.password.result
  final_snapshot_identifier           = "consignment-api-db-final-snapshot-${random_string.snapshot_prefix.result}-${var.environment}"
  storage_encrypted                   = true
  kms_key_id                          = var.kms_key_id
  vpc_security_group_ids              = aws_security_group.database.*.id
  db_subnet_group_name                = aws_db_subnet_group.consignment_api_subnet_group.name
  enabled_cloudwatch_logs_exports     = ["postgresql"]
  backup_retention_period             = 7
  deletion_protection                 = true
  iam_database_authentication_enabled = true
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
  count                = 2
  identifier_prefix    = "content-db-postgres-instance-${var.environment}"
  cluster_identifier   = aws_rds_cluster.consignment_api_database.id
  engine               = "aurora-postgresql"
  engine_version       = "11.9"
  instance_class       = "db.t3.medium"
  db_subnet_group_name = aws_db_subnet_group.consignment_api_subnet_group.name
}
