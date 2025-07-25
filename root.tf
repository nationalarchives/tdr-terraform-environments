module "global_parameters" {
  source = "./tdr-configurations/terraform"
}

module "tre_configuration" {
  source  = "./da-terraform-configurations"
  project = "tre"
}

module "dr2_configuration" {
  source  = "./da-terraform-configurations"
  project = "dr2"
}

module "talend_configuration" {
  source  = "./da-terraform-configurations"
  project = "talend"
}

module "tdr_configuration" {
  source  = "./da-terraform-configurations"
  project = "tdr"
}

module "aws_backup_configuration" {
  source  = "./da-terraform-configurations"
  project = "aws-backup"
}

module "shared_vpc" {
  source                      = "./modules/shared-vpc"
  az_count                    = 2
  common_tags                 = local.common_tags
  environment                 = local.environment
  database_availability_zones = local.database_availability_zones
}

module "database_migrations" {
  source          = "./modules/database-migrations"
  environment     = local.environment
  vpc_id          = module.shared_vpc.vpc_id
  private_subnets = module.shared_vpc.private_subnets
  common_tags     = local.common_tags
  db_url          = module.consignment_api_database.database_url
  db_instance_id  = module.consignment_api_database.resource_id
}

module "consignment_api" {
  source                         = "./modules/consignment-api"
  dns_zone_id                    = local.dns_zone_id
  alb_dns_name                   = module.consignment_api_alb.alb_dns_name
  alb_target_group_arn           = module.consignment_api_alb.alb_target_group_arn
  alb_zone_id                    = module.consignment_api_alb.alb_zone_id
  app_name                       = "consignmentapi"
  common_tags                    = local.common_tags
  database_availability_zones    = local.database_availability_zones
  environment                    = local.environment
  environment_full_name          = local.environment_full_name_map[local.environment]
  private_subnets                = module.shared_vpc.private_subnets
  backend_checks_subnets         = module.shared_vpc.private_backend_checks_subnets
  public_subnets                 = module.shared_vpc.public_subnets
  vpc_id                         = module.shared_vpc.vpc_id
  region                         = local.region
  db_migration_sg                = module.database_migrations.db_migration_security_group
  auth_url                       = local.keycloak_auth_url
  kms_key_id                     = module.encryption_key.kms_key_arn
  frontend_url                   = module.frontend.frontend_url
  dns_zone_name_trimmed          = local.dns_zone_name_trimmed
  db_instance_resource_id        = module.consignment_api_database.resource_id
  create_users_security_group_id = flatten([module.create_db_users_lambda.create_users_lambda_security_group_id, module.create_bastion_user_lambda.create_users_lambda_security_group_id])
  da_reference_generator_url     = local.da_reference_generator_url
  da_reference_generator_limit   = local.da_reference_generator_limit
  aws_guardduty_ecr_arn          = local.aws_guardduty_ecr_arn
  akka_licence_key_name          = local.akka_licence_key_name
}

module "frontend" {
  app_name                         = "frontend"
  source                           = "./modules/transfer-frontend"
  alb_dns_name                     = module.frontend_alb.alb_dns_name
  alb_target_group_arn             = module.frontend_alb.alb_target_group_arn
  alb_zone_id                      = module.frontend_alb.alb_zone_id
  dns_zone_id                      = local.dns_zone_id
  environment                      = local.environment
  environment_full_name            = local.environment_full_name_map[local.environment]
  common_tags                      = local.common_tags
  ip_allowlist                     = local.environment == "intg" ? local.ip_allowlist : ["0.0.0.0/0"]
  region                           = local.region
  vpc_id                           = module.shared_vpc.vpc_id
  public_subnets                   = module.shared_vpc.public_subnets
  private_subnets                  = module.shared_vpc.private_subnets
  dns_zone_name_trimmed            = local.dns_zone_name_trimmed
  auth_url                         = local.keycloak_auth_url
  client_secret_path               = module.keycloak_ssm_parameters.params[local.keycloak_tdr_client_secret_name].name
  read_client_secret_path          = module.keycloak_ssm_parameters.params[local.keycloak_tdr_read_client_secret_name].name
  export_api_url                   = module.export_api.api_url
  backend_checks_api_url           = module.backend_checks_api.api_url
  alb_id                           = module.frontend_alb.alb_id
  public_subnet_ranges             = module.shared_vpc.public_subnet_ranges
  otel_service_name                = "frontend-${local.environment}"
  block_skip_metadata_review       = local.block_skip_metadata_review
  draft_metadata_validator_api_url = module.draft_metadata_api_gateway.api_url
  draft_metadata_s3_kms_keys       = jsonencode([module.s3_internal_kms_key.kms_key_arn])
  draft_metadata_s3_bucket_name    = local.draft_metadata_s3_bucket_name
  notification_sns_topic_arn       = module.notifications_topic.sns_arn
  notifications_topic_kms_key_arn  = module.encryption_key.kms_key_arn
  aws_guardduty_ecr_arn            = local.aws_guardduty_ecr_arn
}

module "alb_logs_s3" {
  source        = "./tdr-terraform-modules/s3"
  project       = var.project
  function      = "alb-logs"
  access_logs   = false
  bucket_policy = "alb_logging_euwest2"
  common_tags   = local.common_tags
}

module "upload_bucket" {
  source                    = "./tdr-terraform-modules/s3"
  project                   = var.project
  function                  = "upload-files"
  bucket_key_enabled        = local.internal_bucket_key_enabled
  kms_key_id                = local.internal_s3_encryption_key_arn
  common_tags               = local.common_tags
  lifecycle_rules           = local.environment == "prod" ? [] : local.non_prod_default_bucket_lifecycle_rules
  aws_backup_local_role_arn = local.aws_back_up_local_role
  s3_bucket_additional_tags = local.aws_back_up_tags
}

module "upload_bucket_quarantine" {
  source                    = "./tdr-terraform-modules/s3"
  project                   = var.project
  function                  = "upload-files-quarantine"
  bucket_key_enabled        = local.internal_bucket_key_enabled
  kms_key_id                = local.internal_s3_encryption_key_arn
  common_tags               = local.common_tags
  lifecycle_rules           = local.environment == "prod" ? [] : local.non_prod_default_bucket_lifecycle_rules
  aws_backup_local_role_arn = local.aws_back_up_local_role
  s3_bucket_additional_tags = local.aws_back_up_tags
}

module "upload_file_cloudfront_dirty_s3" {
  source                       = "./tdr-terraform-modules/s3"
  project                      = var.project
  function                     = "upload-files-cloudfront-dirty"
  bucket_key_enabled           = local.upload_dirty_bucket_key_enabled
  kms_key_id                   = local.upload_dirty_s3_encryption_key_arn
  common_tags                  = local.common_tags
  cors_urls                    = local.upload_cors_urls
  bucket_policy                = "cloudfront_origin"
  abort_incomplete_uploads     = true
  cloudfront_oai               = module.cloudfront_upload.cloudfront_oai_iam_arn
  cloudfront_distribution_arns = [module.cloudfront_upload.cloudfront_arn]
  lifecycle_rules              = local.dirty_bucket_lifecycle_rules
  aws_backup_local_role_arn    = local.aws_back_up_local_role
  s3_bucket_additional_tags    = local.aws_back_up_tags
}

module "upload_file_cloudfront_logs" {
  source                       = "./tdr-terraform-modules/s3"
  project                      = var.project
  function                     = "upload-cloudfront-logs"
  common_tags                  = local.common_tags
  bucket_policy                = "upload_cloudfront_logs"
  aws_logs_delivery_account_id = local.aws_logs_delivery_account_id
  access_logs                  = false
}

module "cloudfront_upload" {
  source                              = "./tdr-terraform-modules/cloudfront"
  s3_regional_domain_name             = module.upload_file_cloudfront_dirty_s3.s3_bucket_regional_domain_name
  environment                         = local.environment
  logging_bucket_regional_domain_name = module.upload_file_cloudfront_logs.s3_bucket_regional_domain_name
  alias_domain_name                   = local.upload_domain
  certificate_arn                     = module.cloudfront_certificate.certificate_arn
  api_gateway_url                     = module.signed_cookies_api.api_url
  sse_kms_enabled                     = local.upload_dirty_bucket_key_enabled
}

module "cloudfront_upload_dns" {
  source                = "./tdr-terraform-modules/route53"
  common_tags           = local.common_tags
  environment_full_name = local.environment_full_name
  project               = var.project
  create_hosted_zone    = false
  a_record_name         = "upload"
  hosted_zone_id        = data.aws_route53_zone.tdr_dns_zone.id
  alb_dns_name          = module.cloudfront_upload.cloudfront_domain_name
  alb_zone_id           = module.cloudfront_upload.cloudfront_hosted_zone_id
}

module "consignment_api_certificate" {
  source      = "./tdr-terraform-modules/certificatemanager"
  project     = var.project
  function    = "consignment-api"
  dns_zone    = local.environment_domain
  domain_name = "api.${local.environment_domain}"
  common_tags = local.common_tags
}

module "cloudfront_certificate" {
  source      = "./tdr-terraform-modules/certificatemanager"
  common_tags = local.common_tags
  dns_zone    = local.environment_domain
  domain_name = local.upload_domain
  function    = "cloudfront-upload"
  project     = var.project
  providers = {
    aws = aws.useast1
  }
}

module "consignment_api_alb" {
  source                = "./tdr-terraform-modules/alb"
  project               = var.project
  function              = "consignmentapi"
  environment           = local.environment
  alb_log_bucket        = module.alb_logs_s3.s3_bucket_id
  alb_security_group_id = module.consignment_api.alb_security_group_id
  alb_target_group_port = 8080
  alb_target_type       = "ip"
  certificate_arn       = module.consignment_api_certificate.certificate_arn
  health_check_matcher  = "200,303"
  health_check_path     = "healthcheck"
  http_listener         = false
  public_subnets        = module.shared_vpc.public_subnets
  vpc_id                = module.shared_vpc.vpc_id
  common_tags           = local.common_tags
  idle_timeout          = 180
}

module "keycloak_certificate" {
  source      = "./tdr-terraform-modules/certificatemanager"
  project     = var.project
  function    = "keycloak"
  dns_zone    = local.environment_domain
  domain_name = "auth.${local.environment_domain}"
  common_tags = local.common_tags
}

module "frontend_certificate" {
  source      = "./tdr-terraform-modules/certificatemanager"
  project     = var.project
  function    = "frontend"
  dns_zone    = local.environment_domain
  domain_name = local.environment_domain
  common_tags = local.common_tags
}

# The frontend uses the network interface IPs which are created for this load balancer.
# If any changes are made to this load balancer which will cause a redeploy then the front end will also need to be deployed.
module "frontend_alb" {
  source                = "./tdr-terraform-modules/alb"
  project               = var.project
  function              = "frontend"
  environment           = local.environment
  alb_log_bucket        = module.alb_logs_s3.s3_bucket_id
  alb_security_group_id = module.frontend.alb_security_group_id
  alb_target_group_port = 9000
  alb_target_type       = "ip"
  certificate_arn       = module.frontend_certificate.certificate_arn
  # The front end returns 308 for any non https requests and the health checks are not https. The play app needs to be running to return 308 so this still works as a health check.
  health_check_matcher = "308"
  health_check_path    = ""
  public_subnets       = module.shared_vpc.public_subnets
  vpc_id               = module.shared_vpc.vpc_id
  common_tags          = local.common_tags
  http_listener        = false
}

module "encryption_key" {
  source                      = "./tdr-terraform-modules/kms"
  project                     = var.project
  function                    = "encryption"
  key_policy                  = "message_system_access"
  environment                 = local.environment
  common_tags                 = local.common_tags
  aws_backup_service_role_arn = local.aws_back_up_service_role
  aws_backup_local_role_arn   = local.aws_back_up_local_role
}

module "waf" {
  # a single WAF web acl and rules are used for all services to minimise AWS costs
  source            = "./tdr-terraform-modules/waf"
  project           = var.project
  function          = "apps"
  environment       = local.environment
  common_tags       = local.common_tags
  alb_target_groups = [module.keycloak_tdr_alb.alb_arn, module.consignment_api_alb.alb_arn, module.frontend_alb.alb_arn]
  trusted_ips       = concat(local.ip_allowlist, tolist(["${module.shared_vpc.nat_gateway_public_ips[0]}/32", "${module.shared_vpc.nat_gateway_public_ips[1]}/32"]))
  blocked_ips       = local.ip_blocked_list
  geo_match         = split(",", var.geo_match)
  restricted_uri    = "admin"
  log_destinations  = [module.waf_cloudwatch.log_group_arn]
}

module "backend_lambda_function_bucket" {
  source          = "./tdr-terraform-modules/s3"
  common_tags     = local.common_tags
  function        = "backend-checks"
  project         = var.project
  lifecycle_rules = local.backend_checks_results_bucket_lifecycle_rules
}

module "create_db_users_lambda" {
  source                  = "./tdr-terraform-modules/lambda"
  project                 = var.project
  common_tags             = local.common_tags
  lambda_create_db_users  = true
  vpc_id                  = module.shared_vpc.vpc_id
  private_subnet_ids      = module.shared_vpc.private_backend_checks_subnets
  db_url                  = module.consignment_api_database.database_url
  db_secrets_arn          = module.consignment_api_database.database_master_user_secret_arn
  kms_key_arn             = module.encryption_key.kms_key_arn
  database_security_group = module.api_database_security_group.security_group_id
  lambda_name             = "create-db-users"
  database_name           = "consignmentapi"
}

module "create_bastion_user_lambda" {
  source                  = "./tdr-terraform-modules/lambda"
  project                 = var.project
  common_tags             = local.common_tags
  lambda_create_db_users  = true
  vpc_id                  = module.shared_vpc.vpc_id
  private_subnet_ids      = module.shared_vpc.private_backend_checks_subnets
  db_url                  = module.consignment_api_database.database_url
  db_secrets_arn          = module.consignment_api_database.database_master_user_secret_arn
  kms_key_arn             = module.encryption_key.kms_key_arn
  database_security_group = module.api_database_security_group.security_group_id
  lambda_name             = "create-bastion-user"
  database_name           = "bastion"
}

module "service_unavailable_lambda" {
  source                     = "./tdr-terraform-modules/lambda"
  project                    = var.project
  common_tags                = local.common_tags
  lambda_service_unavailable = true
  vpc_id                     = module.shared_vpc.vpc_id
  private_subnet_ids         = module.shared_vpc.private_backend_checks_subnets
}

module "api_gateway_account" {
  source      = "./tdr-terraform-modules/api_gateway_account"
  environment = local.environment
}

module "export_api_policy" {
  source        = "./tdr-terraform-modules/iam_policy"
  name          = "TDRExportAPIPolicy${title(local.environment)}"
  policy_string = templatefile("./templates/iam_policy/api_gateway_state_machine_policy.json.tpl", { account_id = data.aws_caller_identity.current.account_id, state_machine_arn = module.export_step_function.state_machine_arn })
}

module "export_api_role" {
  source             = "./tdr-terraform-modules/iam_role"
  assume_role_policy = templatefile("./templates/iam_policy/api_gateway_assume_role_policy.json.tpl", { account_id = data.aws_caller_identity.current.id })
  common_tags        = local.common_tags
  name               = "TDRExportAPIRole${title(local.environment)}"
  policy_attachments = {
    export_policy = module.export_api_policy.policy_arn
  }
}

module "export_api" {
  source      = "./tdr-terraform-modules/apigateway"
  api_name    = "ExportAPI"
  environment = local.environment
  common_tags = local.common_tags
  api_definition = templatefile("./templates/api_gateway/export_api.json.tpl", {
    environment       = local.environment,
    title             = "Export API",
    role_arn          = module.export_api_role.role.arn,
    region            = local.region
    state_machine_arn = module.export_step_function.state_machine_arn
    lambda_arn        = module.export_authoriser_lambda.export_api_authoriser_arn
  })
}

module "signed_cookies_api" {
  source   = "./tdr-terraform-modules/apigateway"
  api_name = "SignedCookiesAPI"
  api_definition = templatefile("./templates/api_gateway/sign_cookies_api.json.tpl", {
    lambda_arn       = module.signed_cookies_lambda.signed_cookies_arn,
    upload_cors_urls = module.frontend.frontend_url
    environment      = local.environment,
    title            = "Sign Cookies API",
    region           = local.region
  })
  environment = local.environment
  common_tags = local.common_tags
}

module "export_authoriser_lambda" {
  source                   = "./tdr-terraform-modules/lambda"
  common_tags              = local.common_tags
  project                  = "tdr"
  lambda_export_authoriser = true
  timeout_seconds          = 10
  api_url                  = module.consignment_api.api_url
  api_gateway_arn          = module.export_api.api_arn
  backend_checks_api_arn   = module.backend_checks_api.api_arn
  draft_metadata_api_arn   = module.draft_metadata_api_gateway.api_execution_arn
  kms_key_arn              = module.encryption_key.kms_key_arn
  private_subnet_ids       = module.shared_vpc.private_backend_checks_subnets
  vpc_id                   = module.shared_vpc.vpc_id
  efs_security_group_id    = module.export_efs.security_group_id

}

module "signed_cookies_lambda" {
  source                    = "./tdr-terraform-modules/lambda"
  common_tags               = local.common_tags
  project                   = "tdr"
  lambda_signed_cookies     = true
  upload_domain             = local.upload_domain
  auth_url                  = local.keycloak_auth_url
  frontend_url              = module.frontend.frontend_url
  cloudfront_key_pair_id    = module.cloudfront_upload.cloudfront_key_pair_id
  timeout_seconds           = 60
  api_gateway_arn           = module.signed_cookies_api.api_arn
  kms_key_arn               = module.encryption_key.kms_key_arn
  private_subnet_ids        = module.shared_vpc.private_backend_checks_subnets
  vpc_id                    = module.shared_vpc.vpc_id
  environment_full          = local.environment_full_name
  user_session_timeout_mins = local.user_session_timeout_mins
}

module "export_status_update_lambda" {
  source                            = "./tdr-terraform-modules/lambda"
  common_tags                       = local.common_tags
  project                           = "tdr"
  lambda_export_status_update       = true
  auth_url                          = local.keycloak_auth_url
  timeout_seconds                   = 60
  private_subnet_ids                = module.shared_vpc.private_backend_checks_subnets
  vpc_id                            = module.shared_vpc.vpc_id
  environment_full                  = local.environment_full_name
  api_url                           = "${module.consignment_api.api_url}/graphql"
  backend_checks_client_secret_path = local.keycloak_backend_checks_secret_name
}

module "reporting_lambda" {
  source                           = "./tdr-terraform-modules/lambda"
  common_tags                      = local.common_tags
  project                          = "tdr"
  lambda_reporting                 = true
  upload_domain                    = local.upload_domain
  auth_url                         = local.keycloak_auth_url
  api_url                          = module.consignment_api.api_url
  keycloak_reporting_client_id     = local.keycloak_reporting_client_id
  keycloak_reporting_client_secret = module.keycloak_ssm_parameters.params[local.keycloak_reporting_client_secret_name].value
  reporting_client_secret_path     = local.keycloak_reporting_client_secret_name
  slack_bot_token                  = module.keycloak_ssm_parameters.params[local.slack_bot_token_name].value
  tdr_reporting_slack_channel_id   = module.reporting_lambda_ssm_parameters.params[local.tdr_reporting_slack_channel_id].value
  timeout_seconds                  = 120
  kms_key_arn                      = module.encryption_key.kms_key_arn
  private_subnet_ids               = module.shared_vpc.private_backend_checks_subnets
  vpc_id                           = module.shared_vpc.vpc_id
}


//create a new efs volume, ECS task attached to the volume and pass in the proper variables and create ECR repository in the backend project

module "export_efs" {
  source                       = "./tdr-terraform-modules/efs"
  common_tags                  = local.common_tags
  function                     = "export-efs"
  project                      = var.project
  access_point_path            = "/export"
  policy                       = "efs_access_policy"
  policy_roles                 = jsonencode(module.consignment_export_task_role.role.arn)
  mount_target_security_groups = flatten([module.consignment_export_ecs_security_group.security_group_id])
  bastion_role                 = module.bastion_role.role.arn
  netnum_offset                = 6
  nat_gateway_ids              = module.shared_vpc.nat_gateway_ids
  vpc_cidr_block               = module.shared_vpc.vpc_cidr_block
  vpc_id                       = module.shared_vpc.vpc_id
}

module "export_step_function" {
  source = "./tdr-terraform-modules/stepfunctions"
  tags   = local.common_tags
  definition = templatefile("./templates/step_function/consignment_export_definition.json.tpl", {
    account_id                    = data.aws_caller_identity.current.account_id
    environment                   = local.environment
    security_groups               = jsonencode([module.consignment_export_ecs_security_group.security_group_id]),
    subnet_ids                    = jsonencode(module.export_efs.private_subnets),
    cluster_arn                   = module.consignment_export_ecs_task.cluster_arn,
    task_arn                      = module.consignment_export_ecs_task.task_definition_arn,
    task_name                     = "consignment-export",
    sns_topic                     = module.notifications_topic.sns_arn,
    platform_version              = "1.4.0"
    max_attempts                  = 2,
    export_output_bucket          = local.flat_format_bucket_name
    export_output_judgment_bucket = local.flat_format_judgment_bucket_name
    bagit_export_bucket           = module.export_bucket.s3_bucket_name
    bagit_export_judgment_bucket  = module.export_bucket_judgment.s3_bucket_name
  })
  step_function_name = "ConsignmentExport"
  environment        = local.environment
  project            = var.project
  policy = templatefile("./templates/iam_policy/consignment_export_policy.json.tpl", {
    task_arn       = module.consignment_export_ecs_task.task_definition_arn,
    execution_role = module.consignment_export_execution_role.role.arn,
    task_role      = module.consignment_export_task_role.role.arn,
    kms_key_arn    = module.encryption_key.kms_key_arn
    account_id     = data.aws_caller_identity.current.account_id
    sns_topic      = module.notifications_topic.sns_arn
    environment    = local.environment
  })
}

module "flat_format_export_bucket" {
  source      = "./da-terraform-modules/s3"
  bucket_name = local.flat_format_bucket_name
  kms_key_arn = module.s3_external_kms_key.kms_key_arn
  common_tags = local.common_tags
  bucket_policy = templatefile("${path.module}/templates/s3/allow_read_access.json.tpl", {
    bucket_name           = local.flat_format_bucket_name
    read_access_roles     = [local.dr2_copy_files_role]
    aws_backup_local_role = local.aws_back_up_local_role
  })
  lifecycle_rules                = local.environment == "prod" ? [] : local.non_prod_default_bucket_lifecycle_rules
  s3_data_bucket_additional_tags = local.aws_back_up_tags
}

module "flat_format_export_bucket_judgment" {
  source      = "./da-terraform-modules/s3"
  bucket_name = local.flat_format_judgment_bucket_name
  kms_key_arn = module.s3_external_kms_key.kms_key_arn
  common_tags = local.common_tags
  bucket_policy = templatefile("${path.module}/templates/s3/allow_read_access.json.tpl", {
    bucket_name           = local.flat_format_judgment_bucket_name
    read_access_roles     = [local.dr2_copy_files_role]
    aws_backup_local_role = local.aws_back_up_local_role
  })
  lifecycle_rules                = local.environment == "prod" ? [] : local.non_prod_default_bucket_lifecycle_rules
  s3_data_bucket_additional_tags = local.aws_back_up_tags
}

module "external_sns_notifications_topic" {
  source      = "./da-terraform-modules/sns"
  tags        = local.common_tags
  topic_name  = local.external_notifications_topic
  kms_key_arn = module.sns_external_kms_key.kms_key_arn
  sns_policy = templatefile("${path.module}/templates/sns/external_notifications_policy.json.tpl", {
    export_role        = module.consignment_export_task_role.role.arn
    dr2_account_number = module.dr2_configuration.account_numbers[local.environment]
    region             = "eu-west-2"
    account_id         = data.aws_caller_identity.current.account_id
    topic_name         = local.external_notifications_topic
  })
}

module "export_bucket" {
  source                    = "./tdr-terraform-modules/s3"
  project                   = var.project
  function                  = "consignment-export"
  common_tags               = local.common_tags
  kms_key_id                = module.s3_external_kms_key.kms_key_arn
  bucket_key_enabled        = true
  read_access_role_arns     = local.standard_export_bucket_read_access_roles
  bucket_policy             = "export_bucket"
  s3_bucket_additional_tags = local.aws_back_up_tags
  aws_backup_local_role_arn = local.aws_back_up_local_role
  lifecycle_rules           = local.environment == "prod" ? [] : local.non_prod_default_bucket_lifecycle_rules
}

module "export_bucket_judgment" {
  source                    = "./tdr-terraform-modules/s3"
  project                   = var.project
  function                  = "consignment-export-judgment"
  common_tags               = local.common_tags
  kms_key_id                = module.s3_external_kms_key.kms_key_arn
  bucket_key_enabled        = true
  read_access_role_arns     = local.judgment_export_bucket_read_access_roles
  bucket_policy             = "export_bucket"
  lifecycle_rules           = local.environment == "prod" ? [] : local.non_prod_default_bucket_lifecycle_rules
  s3_bucket_additional_tags = local.aws_back_up_tags
  aws_backup_local_role_arn = local.aws_back_up_local_role
}

module "notifications_topic" {
  source      = "./tdr-terraform-modules/sns"
  common_tags = local.common_tags
  function    = "notifications"
  project     = var.project
  sns_policy  = "notifications"
  kms_key_arn = module.encryption_key.kms_key_arn
}

module "notification_lambda" {
  source                         = "./tdr-terraform-modules/lambda"
  common_tags                    = local.common_tags
  project                        = "tdr"
  lambda_ecr_scan_notifications  = true
  kms_key_arn                    = module.encryption_key.kms_key_arn
  kms_export_bucket_key_arn      = module.s3_external_kms_key.kms_key_arn
  event_rule_arns                = []
  sns_topic_arns                 = [module.notifications_topic.sns_arn]
  muted_scan_alerts              = module.global_parameters.muted_ecr_scan_alerts
  judgment_export_s3_bucket_name = module.export_bucket_judgment.s3_bucket_name
  standard_export_s3_bucket_name = module.export_bucket.s3_bucket_name
  da_event_bus_arn               = local.da_event_bus_arn
  da_event_bus_kms_key_arn       = local.da_event_bus_kms_key
  notifications_vpc_config = {
    subnet_ids         = module.shared_vpc.private_subnets
    security_group_ids = [module.outbound_only_security_group.security_group_id]
  }
}

module "tdr_public_nacl" {
  source = "./tdr-terraform-modules/nacl"
  name   = "tdr-public-nacl-${local.environment}"
  vpc_id = module.shared_vpc.vpc_id
  ingress_rules = [
    { rule_no = 100, cidr_block = "0.0.0.0/0", action = "allow", from_port = 443, to_port = 443, egress = false },
    { rule_no = 200, cidr_block = "0.0.0.0/0", action = "allow", from_port = 1024, to_port = 65535, egress = false },
    { rule_no = 100, cidr_block = "0.0.0.0/0", action = "allow", from_port = 443, to_port = 443, egress = true },
    { rule_no = 200, cidr_block = "0.0.0.0/0", action = "allow", from_port = 1024, to_port = 65535, egress = true },
  ]
  subnet_ids  = module.shared_vpc.public_subnets
  common_tags = local.common_tags
}


module "tdr_private_nacl" {
  source = "./tdr-terraform-modules/nacl"
  name   = "tdr-private-nacl-${local.environment}"
  vpc_id = module.shared_vpc.vpc_id
  ingress_rules = [
    { rule_no = 100, cidr_block = "0.0.0.0/0", action = "allow", from_port = 1024, to_port = 65535, egress = false },
    { rule_no = 200, cidr_block = "0.0.0.0/0", action = "allow", from_port = 443, to_port = 443, egress = false },
    { rule_no = 100, cidr_block = "0.0.0.0/0", action = "allow", from_port = 443, to_port = 443, egress = true },
    { rule_no = 200, cidr_block = module.shared_vpc.vpc_cidr_block, action = "allow", from_port = 1024, to_port = 65535, egress = true }
  ]
  subnet_ids  = flatten([module.shared_vpc.private_backend_checks_subnets, module.export_efs.private_subnets, module.shared_vpc.private_subnets])
  common_tags = local.common_tags
}

module "tdr_default_nacl" {
  source                 = "./tdr-terraform-modules/default_nacl"
  default_network_acl_id = module.shared_vpc.default_nacl_id
}

module "athena_s3" {
  source      = "./tdr-terraform-modules/s3"
  project     = var.project
  common_tags = local.common_tags
  function    = "athena"
  access_logs = false
}

module "athena" {
  source      = "./tdr-terraform-modules/athena"
  project     = var.project
  common_tags = local.common_tags
  function    = "security_logs"
  bucket      = module.athena_s3.s3_bucket_id
  environment = local.environment
  queries = [
    "create_table_keycloak_alb_logs",
    "create_table_frontend_alb_logs",
    "create_table_consignmentapi_alb_logs",
    "create_table_tdr_cloudtrail_logs",
    "create_table_tdr_s3_upload_logs",
    "tdr_alb_client_ip_count",
    "tdr_alb_error_counts",
    "tdr_cloudtrail_action_for_iam_user",
    "tdr_cloudtrail_action_for_principal",
    "tdr_cloudtrail_action_for_role_name",
    "tdr_cloudtrail_action_on_date",
    "tdr_cloudtrail_ip_for_access_key",
    "tdr_cloudtrail_update_resource",
    "tdr_cloudtrail_user_for_access_key",
    "tdr_s3_deleted_objects",
    "tdr_s3_object_operations",
    "tdr_s3_request_errors"
  ]
}
// Create bastion role here so we can attach it to the EFS file system policy as you can't add roles that don't exist
// We'll attach policies to the role when the bastion is created.
module "bastion_role" {
  source = "./tdr-terraform-modules/iam_role"
  assume_role_policy = templatefile("./tdr-terraform-modules/ec2/templates/ec2_assume_role.json.tpl", {
  account_id = data.aws_caller_identity.current.id })
  common_tags        = local.common_tags
  name               = "BastionEC2Role${title(local.environment)}"
  policy_attachments = {}
}

module "s3_vpc_endpoint" {
  source       = "./tdr-terraform-modules/endpoint"
  common_tags  = local.common_tags
  service_name = "com.amazonaws.${local.region}.s3"
  vpc_id       = module.shared_vpc.vpc_id
  policy = templatefile("${path.module}/templates/endpoint_policies/s3_endpoint_policy.json.tpl",
    {
      environment            = local.environment
      upload_bucket_name     = module.upload_bucket.s3_bucket_name,
      quarantine_bucket_name = module.upload_bucket_quarantine.s3_bucket_name,
      antivirus_role         = module.yara_av_v2.lambda_role_arn,
      export_task_role       = module.consignment_export_task_role.role.arn,
      export_bucket_name     = module.export_bucket.s3_bucket_name,
      account_id             = data.aws_caller_identity.current.account_id
    }
  )
}

module "create_keycloak_users_api_lambda" {
  source                           = "./tdr-terraform-modules/lambda"
  common_tags                      = local.common_tags
  project                          = var.project
  user_admin_client_secret         = module.keycloak_ssm_parameters.params[local.keycloak_user_admin_client_secret_name].value
  user_admin_client_secret_path    = local.keycloak_user_admin_client_secret_name
  kms_key_arn                      = module.encryption_key.kms_key_arn
  auth_url                         = local.keycloak_auth_url
  vpc_id                           = module.shared_vpc.vpc_id
  lambda_create_keycloak_user_api  = true
  private_subnet_ids               = module.shared_vpc.private_backend_checks_subnets
  keycloak_user_management_api_arn = module.create_keycloak_users_api.api_arn
}

module "create_keycloak_users_s3_lambda" {
  source                         = "./tdr-terraform-modules/lambda"
  common_tags                    = local.common_tags
  project                        = var.project
  user_admin_client_secret       = module.keycloak_ssm_parameters.params[local.keycloak_user_admin_client_secret_name].value
  user_admin_client_secret_path  = local.keycloak_user_admin_client_secret_name
  kms_key_arn                    = module.encryption_key.kms_key_arn
  auth_url                       = local.keycloak_auth_url
  vpc_id                         = module.shared_vpc.vpc_id
  lambda_create_keycloak_user_s3 = true
  private_subnet_ids             = module.shared_vpc.private_backend_checks_subnets
  s3_bucket_arn                  = module.create_bulk_users_bucket.s3_bucket_arn
}

module "inactive_keycloak_users_lambda" {
  source        = "./da-terraform-modules/lambda"
  function_name = local.inactive_keycloak_users_function_name
  tags          = local.common_tags
  handler       = "uk.gov.nationalarchives.keycloak.users.InactiveKeycloakUsersLambda::handleRequest"
  runtime       = local.runtime_java_21
  timeout_seconds = 240
  policies = {
    "TDRInactiveKeycloakUsersLambdaPolicy${title(local.environment)}" = templatefile("./templates/iam_policy/inactive_keycloak_users_lambda.json.tpl", {
      function_name                 = local.inactive_keycloak_users_function_name
      account_id                    = var.tdr_account_number
      kms_arn                       = module.encryption_key.kms_key_arn
      user_admin_client_secret_path = local.keycloak_user_admin_client_secret_name
      reporting_client_secret_path  = local.keycloak_reporting_client_secret_name
    })
  }
  plaintext_env_vars = {
    AUTH_URL                      = local.keycloak_auth_url
    API_URL                       = "${module.consignment_api.api_url}/graphql"
    USER_ADMIN_CLIENT_SECRET      = module.keycloak_ssm_parameters.params[local.keycloak_user_admin_client_secret_name].value
    USER_ADMIN_CLIENT_SECRET_PATH = local.keycloak_user_admin_client_secret_name
    REPORTING_CLIENT_SECRET       = module.keycloak_ssm_parameters.params[local.keycloak_reporting_client_secret_name].value
    REPORTING_CLIENT_SECRET_PATH  = local.keycloak_reporting_client_secret_name
  }
}

module "create_keycloak_users_api" {
  source        = "./tdr-terraform-modules/apigatewayv2"
  body_template = templatefile("${path.module}/templates/api_gateway/create_keycloak_users.json.tpl", { region = local.region, lambda_arn = module.create_keycloak_users_api_lambda.create_keycloak_users_api_lambda_arn, auth_url = local.keycloak_auth_url })
  environment   = local.environment
  api_name      = "CreateKeycloakUsersApi"
  common_tags   = local.common_tags
}

module "create_bulk_users_bucket" {
  source              = "./tdr-terraform-modules/s3"
  common_tags         = local.common_tags
  function            = "create-bulk-keycloak-users"
  project             = var.project
  lambda_notification = true
  lambda_arn          = module.create_keycloak_users_s3_lambda.create_keycloak_users_s3_lambda_arn
}

module "rotate_keycloak_secrets_lambda" {
  source                            = "./tdr-terraform-modules/lambda"
  common_tags                       = local.common_tags
  project                           = "tdr"
  lambda_rotate_keycloak_secrets    = true
  notifications_topic               = module.notifications_topic.sns_arn
  private_subnet_ids                = module.shared_vpc.private_backend_checks_subnets
  auth_url                          = local.keycloak_auth_url
  rotate_secrets_client_path        = local.keycloak_rotate_secrets_client_secret_name
  vpc_id                            = module.shared_vpc.vpc_id
  kms_key_arn                       = module.encryption_key.kms_key_arn
  rotate_keycloak_secrets_event_arn = module.periodic_rotate_keycloak_secrets_event.event_arn
  api_connection_auth_type          = aws_cloudwatch_event_connection.consignment_api_connection.authorization_type
  api_connection_name               = aws_cloudwatch_event_connection.consignment_api_connection.name
  api_connection_secret_arn         = aws_cloudwatch_event_connection.consignment_api_connection.secret_arn
}

module "periodic_rotate_keycloak_secrets_event" {
  source                  = "./tdr-terraform-modules/cloudwatch_events"
  schedule                = "rate(7 days)"
  rule_name               = "rotate-keycloak-secrets"
  lambda_event_target_arn = module.rotate_keycloak_secrets_lambda.rotate_keycloak_secrets_lambda_arn
}

module "advanced_shield" {
  source  = "./tdr-terraform-modules/shield"
  project = var.project
  resource_arns = toset(
    flatten(
      [
        data.aws_route53_zone.tdr_dns_zone.arn,
        module.cloudfront_upload.cloudfront_arn,
        module.keycloak_tdr_alb.alb_arn,
        module.consignment_api_alb.alb_arn,
        module.frontend_alb.alb_arn,
        module.shared_vpc.elastic_ip_arns
      ]
    )
  )
}

module "shield_response_team_role" {
  source             = "./tdr-terraform-modules/iam_role"
  assume_role_policy = templatefile("${path.module}/templates/iam_role/shield_response_assume_role.json.tpl", {})
  common_tags        = local.common_tags
  name               = "TDRShieldResponseTeamRole${title(local.environment)}"
  policy_attachments = {
    access_policy = "arn:aws:iam::aws:policy/service-role/AWSShieldDRTAccessPolicy"
  }
}

module "shield_response_s3_bucket" {
  source      = "./tdr-terraform-modules/s3"
  common_tags = local.common_tags
  function    = "shield-team-information"
  project     = var.project
}

module "shield_cloudwatch_rules" {
  for_each = {
    route_53     = data.aws_route53_zone.tdr_dns_zone.arn,
    cloudfront   = module.cloudfront_upload.cloudfront_arn,
    keycloak_alb = module.keycloak_tdr_alb.alb_arn,
    api_alb      = module.consignment_api_alb.alb_arn,
    frontend_alb = module.frontend_alb.alb_arn,
    elastic_ip_1 = module.shared_vpc.elastic_ip_arns[0
    ],
    elastic_ip_2 = module.shared_vpc.elastic_ip_arns[1]
  }
  source              = "./tdr-terraform-modules/cloudwatch_alarms"
  environment         = local.environment
  function            = "shield-metric-${each.key}"
  metric_name         = "DDoSDetected"
  project             = var.project
  threshold           = 1
  notification_topic  = module.notifications_topic.sns_arn
  dimensions          = { "ResourceArn" = each.value }
  statistic           = "Sum"
  namespace           = "AWS/DDoSProtection"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  datapoints_to_alarm = 1
  evaluation_period   = 20
}

module "api_database_security_group" {
  source      = "./tdr-terraform-modules/security_group"
  common_tags = local.common_tags
  description = "The security group for the API database"
  name        = "tdr-consignment-api-database-instance-${local.environment}"
  vpc_id      = module.shared_vpc.vpc_id
  ingress_security_group_rules = [
    { port = 5432, description = "Allow inbound access from ECS", security_group_id = module.consignment_api.ecs_task_security_group_id },
    { port = 5432, description = "Allow inbound access from database migrations", security_group_id = module.database_migrations.db_migration_security_group },
    { port = 5432, description = "Allow inbound access from create bastion users lambda", security_group_id = module.create_bastion_user_lambda.create_users_lambda_security_group_id[0] },
    { port = 5432, description = "Allow inbound access from create users lambda", security_group_id = module.create_db_users_lambda.create_users_lambda_security_group_id[0] },
    { port = 5432, description = "Allow inbound access from backend checks", security_group_id = module.outbound_with_db_security_group.security_group_id },
    { port = 5432, description = "Allow inbound access from export", security_group_id = module.consignment_export_ecs_security_group.security_group_id }
  ]
  egress_security_group_rules = [
    { port = 5432, description = "Allow outbound access to the ECS tasks security group", security_group_id = module.consignment_api.ecs_task_security_group_id, protocol = "tcp" }
  ]
}

module "consignment_api_database" {
  source                  = "./tdr-terraform-modules/rds_instance"
  admin_username          = "api_admin"
  availability_zone       = local.database_availability_zone
  common_tags             = local.common_tags
  database_name           = "consignmentapi"
  database_version        = "17.4"
  environment             = local.environment
  kms_key_id              = module.encryption_key.kms_key_arn
  private_subnets         = module.shared_vpc.private_subnets
  security_group_ids      = [module.api_database_security_group.security_group_id]
  multi_az                = local.environment == "prod"
  ca_cert_identifier      = local.database_ca_cert_identifier
  backup_retention_period = local.rds_retention_period_days
  apply_immediately       = true
  aws_backup_tag          = local.aws_back_up_tags
}

module "waf_cloudwatch" {
  source      = "./tdr-terraform-modules/cloudwatch_logs"
  common_tags = local.common_tags
  name        = "aws-waf-logs-${local.environment}"
}

module "iam_security_audit_user_group" {
  source         = "./tdr-terraform-modules/iam"
  security_audit = local.security_audit
  environment    = local.environment
}

module "ecs_task_events_log_group" {
  source            = "./tdr-terraform-modules/cloudwatch_logs"
  name              = "/aws/events/ecs-task-events-${local.environment}"
  retention_in_days = 30
  common_tags       = local.common_tags
}

module "ecs_task_stopped_event" {
  source                               = "./tdr-terraform-modules/cloudwatch_events"
  event_pattern                        = "ecs_task_stopped"
  log_group_ecs_task_events_target_arn = module.ecs_task_events_log_group.log_group_arn
  rule_name                            = "ecs-task-state-stopped"
  rule_description                     = "Log to cloudwatch when ECS task state is STOPPED"
}
