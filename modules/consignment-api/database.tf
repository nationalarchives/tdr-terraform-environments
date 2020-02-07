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

resource "aws_kms_key" "encryption" {
  description         = "KMS key for encryption within the environment"
  enable_key_rotation = true
  tags = merge(
    var.common_tags,
    map(
      "Name", "environment-encryption-${var.environment}"
    )
  )
}

resource "aws_kms_alias" "encryption" {
  name          = "alias/environment-encryption-${var.environment}"
  target_key_id = aws_kms_key.encryption.key_id
}

resource "aws_rds_cluster" "consignment_api_database" {
  cluster_identifier_prefix = "consignment-api-db-${var.environment}"
  engine                    = "aurora-mysql"
  engine_version            = "5.7.12"
  availability_zones        = var.database_availability_zones
  database_name             = var.app_name
  master_username           = "api_admin"
  master_password           = random_password.password.result
  final_snapshot_identifier = "user-db-final-snapshot-${random_string.snapshot_prefix.result}-${var.environment}"
  storage_encrypted         = true
  kms_key_id                = aws_kms_alias.encryption.id
  vpc_security_group_ids    = aws_security_group.database.*.id
  db_subnet_group_name      = aws_db_subnet_group.consignment_api_subnet_group.name
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
  cluster_identifier   = aws_rds_cluster.consignment_api_database.id
  engine               = "aurora-mysql"
  instance_class       = "db.t2.small"
  db_subnet_group_name = aws_db_subnet_group.consignment_api_subnet_group.name
}
