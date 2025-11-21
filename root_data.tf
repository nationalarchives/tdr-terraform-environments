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
resource "random_uuid" "slack_bot_token" {}

data "aws_canonical_user_id" "canonical_user" {}

data "aws_ssm_parameter" "slack_success_workflow" {
  name = "/mgmt/slack_success_workflow"
}

data "aws_ssm_parameter" "slack_failure_workflow" {
  name = "/mgmt/slack_failure_workflow"
}

data "aws_ssm_parameter" "workflow_pat" {
  name = "/mgmt/workflow_pat"
}

data "aws_ssm_parameter" "slack_e2e_failure_workflow" {
  name = "/mgmt/slack_e2e_failure_workflow"
}

data "aws_ssm_parameter" "slack_e2e_success_workflow" {
  name = "/mgmt/slack_e2e_success_workflow"
}

data "github_ip_ranges" "actions_ranges" {}

data "aws_organizations_organization" "tna" {}

data "aws_region" "current" {}
