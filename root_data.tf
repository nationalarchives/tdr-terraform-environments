data "aws_ssm_parameter" "cost_centre" {
  name = "/mgmt/cost_centre"
}

data "aws_ssm_parameter" "trusted_ips" {
  name = "/mgmt/trusted_ips"
}

data "aws_route53_zone" "tdr_dns_zone" {
  name = local.environment == "prod" ? "${var.project}.${var.domain}" : "${var.project}-${local.environment_full_name}.${var.domain}"
}

data "aws_ssm_parameter" "keycloak_backend_checks_client_secret" {
  name = "/${local.environment}/keycloak/backend_checks_client/secret"
}
