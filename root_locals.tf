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
      "CostCentre"      = module.global_parameters.cost_centre
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

  ecr_account_number = local.environment == "sbox" ? data.aws_caller_identity.current.account_id : data.aws_ssm_parameter.mgmt_account_number.value

  keycloak_auth_url = "https://auth.${local.dns_zone_name_trimmed}"

  keycloak_backend_checks_secret_name     = "/${local.environment}/keycloak/backend_checks_client/secret"
  keycloak_tdr_client_secret_name         = "/${local.environment}/keycloak/client/secret"
  keycloak_user_password_name             = "/${local.environment}/keycloak/password"
  keycloak_admin_password_name            = "/${local.environment}/keycloak/admin/password"
  keycloak_admin_user_name                = "/${local.environment}/keycloak/admin/user"
  keycloak_realm_admin_client_secret_name = "/${local.environment}/keycloak/realm_admin_client/secret"
  keycloak_configuration_properties_name  = "/${local.environment}/keycloak/configuration_properties"
  keycloak_user_admin_client_secret_name  = "/${local.environment}/keycloak/user_admin_client/secret"
  keycloak_govuk_notify_api_key_name      = "/${local.environment}/keycloak/govuk_notify/api_key"
  keycloak_govuk_notify_template_id_name  = "/${local.environment}/keycloak/govuk_notify/template_id"
  keycloak_reporting_client_secret_name   = "/${local.environment}/keycloak/reporting_client/secret"

  //Used for allowing full access for Cloudfront logging. More information at https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/AccessLogs.html#AccessLogsBucketAndFileOwnership
  logs_delivery_canonical_user_id = "c4c1ede66af53448b93c283ce9448c4ba468c9432aa01d700d3878632f77d2d0"
}
