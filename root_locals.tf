locals {
  environment = terraform.workspace

  assume_role = "arn:aws:iam::${var.tdr_account_number}:role/TDRTerraformRole${title(local.environment)}"

  environment_full_name_map = {
    "intg"    = "integration",
    "staging" = "staging",
    "prod"    = "production"
  }

  environment_full_name = local.environment_full_name_map[local.environment]

  common_tags = tomap(
    {
      "Environment"     = local.environment,
      "Owner"           = "TDR",
      "Terraform"       = true,
      "TerraformSource" = "https://github.com/nationalarchives/tdr-terraform-environments",
      "CostCentre"      = data.aws_ssm_parameter.cost_centre.value
    }
  )
  database_availability_zones = ["eu-west-2a", "eu-west-2b"]

  region = "eu-west-2"

  dns_zone_id = data.aws_route53_zone.tdr_dns_zone.zone_id

  dns_zone_name_trimmed = trimsuffix(data.aws_route53_zone.tdr_dns_zone.name, ".")

  environment_domain = local.environment == "prod" ? "${var.project}.${var.domain}" : "${var.project}-${local.environment_full_name}.${var.domain}"

  upload_domain = "upload.${local.environment_domain}"

  local_dev_frontend_url = "http://localhost:9000"

  upload_cors_urls = local.environment == "intg" ? [module.frontend.frontend_url, local.local_dev_frontend_url] : [module.frontend.frontend_url]

  file_check_lambda_timeouts_in_seconds = {
    "antivirus"      = 180,
    "api_update"     = 20,
    "checksum"       = 180,
    "download_files" = 180,
    "file_format"    = 900
  }

  developer_ip_list = split(",", module.global_parameters.developer_ips)

  trusted_ip_list = split(",", module.global_parameters.trusted_ips)

  ip_allowlist = concat(local.developer_ip_list, local.trusted_ip_list)
}
