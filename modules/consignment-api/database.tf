resource "random_password" "password" {
  length  = 41
  special = false
}

resource "aws_db_subnet_group" "consignment_api_subnet_group" {
  name       = "tdr-${var.environment}"
  subnet_ids = var.private_subnets

  tags = merge(
    var.common_tags,
    tomap(
      { "Name" = "user-db-subnet-group-${var.environment}" }
    )
  )
}

resource "random_string" "snapshot_prefix" {
  length  = 4
  upper   = false
  special = false
}
