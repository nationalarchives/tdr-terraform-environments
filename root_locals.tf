locals {
  environment = terraform.workspace

  assume_role = "arn:aws:iam::${var.tdr_account_number}:role/TDRTerraformRole${title(local.environment)}"

  environment_full_name_map = {
    "intg"    = "integration",
    "staging" = "staging",
    "prod"    = "production"
  }

  environment_full_name = local.environment_full_name_map[local.environment]

  common_tags = map(
    "Environment", local.environment,
    "Owner", "TDR",
    "Terraform", true,
    "CostCentre", data.aws_ssm_parameter.cost_centre.value,
  )
  database_availability_zones = ["eu-west-2a", "eu-west-2b"]

  region = "eu-west-2"

  dns_zone_id = data.aws_route53_zone.tdr_dns_zone.zone_id

  dns_zone_name_trimmed = trimsuffix(data.aws_route53_zone.tdr_dns_zone.name, ".")

  environment_domain = local.environment == "prod" ? "${var.project}.${var.domain}" : "${var.project}-${local.environment_full_name}.${var.domain}"

  developer_ip_list = split(",", module.global_parameters.developer_ips)

  trusted_ip_list = split(",", module.global_parameters.trusted_ips)

  ip_whitelist = concat(local.developer_ip_list, local.trusted_ip_list)
}
