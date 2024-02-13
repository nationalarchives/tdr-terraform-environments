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

  database_availability_zone = "eu-west-2a"

  database_ca_cert_identifier = "rds-ca-rsa2048-g1"

  region = "eu-west-2"

  dns_zone_id = data.aws_route53_zone.tdr_dns_zone.zone_id

  dns_zone_name_trimmed = trimsuffix(data.aws_route53_zone.tdr_dns_zone.name, ".")

  environment_domain = local.environment == "prod" ? "${var.project}.${var.domain}" : "${var.project}-${local.environment_full_name}.${var.domain}"

  s3_endpoint = "https://s3.eu-west-2.amazonaws.com"

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

  user_session_timeout_mins = 60

  keycloak_auth_url = "https://auth.${local.dns_zone_name_trimmed}"

  keycloak_backend_checks_secret_name        = "/${local.environment}/keycloak/backend_checks_client/secret"
  keycloak_tdr_client_secret_name            = "/${local.environment}/keycloak/client/secret"
  keycloak_user_password_name                = "/${local.environment}/keycloak/password"
  keycloak_admin_password_name               = "/${local.environment}/keycloak/admin/password"
  keycloak_admin_user_name                   = "/${local.environment}/keycloak/admin/user"
  keycloak_realm_admin_client_secret_name    = "/${local.environment}/keycloak/realm_admin_client/secret"
  keycloak_configuration_properties_name     = "/${local.environment}/keycloak/configuration_properties"
  keycloak_user_admin_client_secret_name     = "/${local.environment}/keycloak/user_admin_client/secret"
  keycloak_govuk_notify_api_key_name         = "/${local.environment}/keycloak/govuk_notify/api_key"
  keycloak_govuk_notify_template_id_name     = "/${local.environment}/keycloak/govuk_notify/template_id"
  keycloak_reporting_client_secret_name      = "/${local.environment}/keycloak/reporting_client/secret"
  keycloak_rotate_secrets_client_secret_name = "/${local.environment}/keycloak/rotate_secrets_client/secret"
  keycloak_db_url                            = "/${local.environment}/keycloak/instance/url"
  slack_bot_token_name                       = "/${local.environment}/slack/bot"

  keycloak_reporting_client_id      = "tdr-reporting"
  keycloak_backend-checks_client_id = "tdr-backend-checks"

  //Used for allowing full access for Cloudfront logging. More information at https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/AccessLogs.html#AccessLogsBucketAndFileOwnership
  logs_delivery_canonical_user_id = "c4c1ede66af53448b93c283ce9448c4ba468c9432aa01d700d3878632f77d2d0"

  //Set to true to create security audit IAM user group
  security_audit = false

  file_upload_data_function_name       = "${var.project}-file-upload-data-${local.environment}"
  api_update_v2_function_name          = "${var.project}-api-update-v2-${local.environment}"
  backend_checks_results_function_name = "${var.project}-backend-checks-results-${local.environment}"
  yara_av_v2_function_name             = "${var.project}-yara-av-v2-${local.environment}"
  file_format_v2_function_name         = "${var.project}-file-format-v2-${local.environment}"
  checksum_v2_function_name            = "${var.project}-checksum-v2-${local.environment}"
  redacted_files_function_name         = "${var.project}-redacted-files-${local.environment}"
  statuses_function_name               = "${var.project}-statuses-${local.environment}"

  runtime_python_3_9 = "python3.9"
  runtime_python_3_7 = "python3.7"
  runtime_java_11    = "java11"

  upload_files_cloudfront_dirty_bucket_name = "${var.project}-upload-files-cloudfront-dirty-${local.environment}"

  url_path              = "/${local.environment}/consignmentapi/instance/url"
  tmp_directory         = "/tmp"
  consignment_user_name = "consignment_api_user"

  //tre has used different naming conventions for its environment names
  tre_environment     = local.environment == "intg" ? "int" : local.environment
  tre_export_role_arn = module.tre_configuration.terraform_config[local.tre_environment]["s3_export_bucket_reader_arn"]

  // talend only has a role set for intg this will change in the future
  talend_export_role_arn = local.environment == "intg" ? module.talend_configuration.terraform_config[local.environment]["remote_engine_instance_profile_role"] : ""

  standard_export_bucket_read_access_roles = local.environment == "intg" ? [local.tre_export_role_arn, local.talend_export_role_arn] : [local.tre_export_role_arn]
  judgment_export_bucket_read_access_roles = [local.tre_export_role_arn]

  // s3 internal bucket encryption
  internal_s3_encryption_key_arn = local.environment == "intg" ? module.s3_internal_kms_key.kms_key_arn : ""
  internal_bucket_key_enabled    = local.environment == "intg"

  // s3 upload bucket encryption
  upload_dirty_s3_encryption_key_arn = ""
  upload_dirty_bucket_key_enabled    = false

  // event bus hosted on tre environments
  da_event_bus_arn     = module.tre_configuration.terraform_config[local.tre_environment]["da_eventbus"]
  da_event_bus_kms_key = module.tre_configuration.terraform_config["${local.tre_environment}_da_eventbus_kms_arn"]

  da_reference_generator_url   = module.tdr_configuration.terraform_config["reference_generator_${local.environment}_url"]
  da_reference_generator_limit = module.tdr_configuration.terraform_config["reference_generator_limit"]

  //feature access blocks
  block_shared_keycloak_pages = local.environment == "intg" ? false : true
  block_draft_metadata_upload = local.environment == "intg" ? false : true
  
  e2e_testing_role_arn = module.tdr_configuration.terraform_config[local.environment]["e2e_testing_role_arn"]
}
