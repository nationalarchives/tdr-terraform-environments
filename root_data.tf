data "aws_ssm_parameter" "cost_centre" {
  name = "/mgmt/cost_centre"
}

data "aws_route53_zone" "tdr_dns_zone" {
  name = local.environment == "prod" ? "${var.project}.${var.domain}" : "${var.project}-${local.environment_full_name}.${var.domain}"
}

data "aws_caller_identity" "current" {}

data "aws_ssm_parameter" "mgmt_account_number" {
  name = "/mgmt/management_account"
}

resource "random_password" "password" {
  length  = 16
  special = false
}

resource "random_password" "keycloak_password" {
  length  = 16
  special = false
}

resource "random_uuid" "client_secret" {}
resource "random_uuid" "backend_checks_client_secret" {}
resource "random_uuid" "reporting_client_secret" {}
