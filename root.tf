module "global_parameters" {
  source = "./tdr-configurations/terraform"
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
  db_url          = module.consignment_api.database_url
  db_cluster_id   = module.consignment_api.database_cluster_id
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
  public_subnets                 = module.shared_vpc.public_subnets
  vpc_id                         = module.shared_vpc.vpc_id
  region                         = local.region
  db_migration_sg                = module.database_migrations.db_migration_security_group
  auth_url                       = local.keycloak_auth_url
  kms_key_id                     = module.encryption_key.kms_key_arn
  frontend_url                   = module.frontend.frontend_url
  dns_zone_name_trimmed          = local.dns_zone_name_trimmed
  create_users_security_group_id = flatten([module.create_db_users_lambda.create_users_lambda_security_group_id, module.create_bastion_user_lambda.create_users_lambda_security_group_id])
}

module "frontend" {
  app_name              = "frontend"
  source                = "./modules/transfer-frontend"
  alb_dns_name          = module.frontend_alb.alb_dns_name
  alb_target_group_arn  = module.frontend_alb.alb_target_group_arn
  alb_zone_id           = module.frontend_alb.alb_zone_id
  dns_zone_id           = local.dns_zone_id
  environment           = local.environment
  environment_full_name = local.environment_full_name_map[local.environment]
  common_tags           = local.common_tags
  ip_allowlist          = local.environment == "intg" ? local.ip_allowlist : ["0.0.0.0/0"]
  region                = local.region
  vpc_id                = module.shared_vpc.vpc_id
  public_subnets        = module.shared_vpc.public_subnets
  private_subnets       = module.shared_vpc.private_subnets
  dns_zone_name_trimmed = local.dns_zone_name_trimmed
  auth_url              = local.keycloak_auth_url
  client_secret_path    = module.keycloak_ssm_parameters.params[local.keycloak_tdr_client_secret_name].name
  export_api_url        = module.export_api.api_url
  alb_id                = module.frontend_alb.alb_id
  public_subnet_ranges  = module.shared_vpc.public_subnet_ranges
}

module "alb_logs_s3" {
  source        = "./tdr-terraform-modules/s3"
  project       = var.project
  function      = "alb-logs"
  access_logs   = false
  bucket_policy = "alb_logging_euwest2"
  common_tags   = local.common_tags
  kms_key_id    = 1
}

module "upload_bucket" {
  source      = "./tdr-terraform-modules/s3"
  project     = var.project
  function    = "upload-files"
  common_tags = local.common_tags
}

module "upload_bucket_quarantine" {
  source      = "./tdr-terraform-modules/s3"
  project     = var.project
  function    = "upload-files-quarantine"
  common_tags = local.common_tags
}

module "upload_file_cloudfront_dirty_s3" {
  source                   = "./tdr-terraform-modules/s3"
  project                  = var.project
  function                 = "upload-files-cloudfront-dirty"
  common_tags              = local.common_tags
  cors_urls                = local.upload_cors_urls
  sns_topic_arn            = module.dirty_upload_sns_topic.sns_arn
  bucket_policy            = "cloudfront_oai"
  sns_notification         = true
  abort_incomplete_uploads = true
  cloudfront_oai           = module.cloudfront_upload.cloudfront_oai_iam_arn
}

module "upload_file_cloudfront_logs" {
  source      = "./tdr-terraform-modules/s3"
  project     = var.project
  function    = "upload-cloudfront-logs"
  common_tags = local.common_tags
  access_logs = false
  canonical_user_grants = [
    { id = local.logs_delivery_canonical_user_id, permissions = ["FULL_CONTROL"] },
    { id = data.aws_canonical_user_id.canonical_user.id, permissions = ["FULL_CONTROL"] }
  ]
}

module "cloudfront_upload" {
  source                              = "./tdr-terraform-modules/cloudfront"
  s3_regional_domain_name             = module.upload_file_cloudfront_dirty_s3.s3_bucket_regional_domain_name
  environment                         = local.environment
  logging_bucket_regional_domain_name = module.upload_file_cloudfront_logs.s3_bucket_regional_domain_name
  alias_domain_name                   = local.upload_domain
  certificate_arn                     = module.cloudfront_certificate.certificate_arn
  api_gateway_url                     = module.signed_cookies_api.api_url
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
}

module "encryption_key" {
  source           = "./tdr-terraform-modules/kms"
  project          = var.project
  function         = "encryption"
  key_policy       = "message_system_access"
  environment      = local.environment
  common_tags      = local.common_tags
  policy_variables = { transform_engine_retry_role = data.aws_ssm_parameter.transform_engine_retry_role_arn.value }
}

module "waf" {
  # a single WAF web acl and rules are used for all services to minimise AWS costs
  # uses AWS classic WAF - should upgrade to WAFv2 once supported by Terraform
  source            = "./tdr-terraform-modules/waf"
  project           = var.project
  function          = "apps"
  environment       = local.environment
  common_tags       = local.common_tags
  alb_target_groups = [module.keycloak_tdr_alb.alb_arn, module.consignment_api_alb.alb_arn, module.frontend_alb.alb_arn]
  trusted_ips       = concat(local.ip_allowlist, tolist(["${module.shared_vpc.nat_gateway_public_ips[0]}/32", "${module.shared_vpc.nat_gateway_public_ips[1]}/32"]))
  geo_match         = split(",", var.geo_match)
  restricted_uri    = "auth/admin"
}

module "backend_lambda_function_bucket" {
  source      = "./tdr-terraform-modules/s3"
  common_tags = local.common_tags
  function    = "backend-checks"
  project     = var.project
}

module "antivirus_lambda" {
  source                                 = "./tdr-terraform-modules/lambda"
  backend_checks_efs_access_point        = module.backend_checks_efs.access_point
  backend_checks_efs_root_directory_path = module.backend_checks_efs.root_directory_path
  common_tags                            = local.common_tags
  file_system_id                         = module.backend_checks_efs.file_system_id
  lambda_yara_av                         = true
  timeout_seconds                        = local.file_check_lambda_timeouts_in_seconds["antivirus"]
  project                                = var.project
  use_efs                                = true
  vpc_id                                 = module.shared_vpc.vpc_id
  private_subnet_ids                     = module.backend_checks_efs.private_subnets
  mount_target_zero                      = module.backend_checks_efs.mount_target_zero
  mount_target_one                       = module.backend_checks_efs.mount_target_one
  kms_key_arn                            = module.encryption_key.kms_key_arn
  efs_security_group_id                  = module.backend_checks_efs.security_group_id
}

module "checksum_lambda" {
  source                                 = "./tdr-terraform-modules/lambda"
  project                                = var.project
  common_tags                            = local.common_tags
  lambda_checksum                        = true
  timeout_seconds                        = local.file_check_lambda_timeouts_in_seconds["checksum"]
  file_system_id                         = module.backend_checks_efs.file_system_id
  backend_checks_efs_access_point        = module.backend_checks_efs.access_point
  vpc_id                                 = module.shared_vpc.vpc_id
  use_efs                                = true
  backend_checks_efs_root_directory_path = module.backend_checks_efs.root_directory_path
  private_subnet_ids                     = module.backend_checks_efs.private_subnets
  mount_target_zero                      = module.backend_checks_efs.mount_target_zero
  mount_target_one                       = module.backend_checks_efs.mount_target_one
  kms_key_arn                            = module.encryption_key.kms_key_arn
  efs_security_group_id                  = module.backend_checks_efs.security_group_id
}

module "create_db_users_lambda" {
  source                      = "./tdr-terraform-modules/lambda"
  project                     = var.project
  common_tags                 = local.common_tags
  lambda_create_db_users      = true
  vpc_id                      = module.shared_vpc.vpc_id
  private_subnet_ids          = module.backend_checks_efs.private_subnets
  consignment_database_sg_id  = module.consignment_api.consignment_db_security_group_id
  db_admin_user               = module.consignment_api.database_username
  db_admin_password           = module.consignment_api.database_password
  db_url                      = module.consignment_api.database_url
  kms_key_arn                 = module.encryption_key.kms_key_arn
  api_database_security_group = module.consignment_api.database_security_group
  lambda_name                 = "create-db-users"
  database_name               = "consignmentapi"
}

module "create_bastion_user_lambda" {
  source                      = "./tdr-terraform-modules/lambda"
  project                     = var.project
  common_tags                 = local.common_tags
  lambda_create_db_users      = true
  vpc_id                      = module.shared_vpc.vpc_id
  private_subnet_ids          = module.backend_checks_efs.private_subnets
  consignment_database_sg_id  = module.consignment_api.consignment_db_security_group_id
  db_admin_user               = module.consignment_api.database_username
  db_admin_password           = module.consignment_api.database_password
  db_url                      = module.consignment_api.database_url
  kms_key_arn                 = module.encryption_key.kms_key_arn
  api_database_security_group = module.consignment_api.database_security_group
  lambda_name                 = "create-bastion-user"
  database_name               = "bastion"
}

module "dirty_upload_sns_topic" {
  source      = "./tdr-terraform-modules/sns"
  common_tags = local.common_tags
  project     = var.project
  function    = "s3-dirty-upload"
  sns_policy  = "s3_upload"
  kms_key_arn = module.encryption_key.kms_key_arn

}

module "backend_check_failure_sqs_queue" {
  source      = "./tdr-terraform-modules/sqs"
  common_tags = local.common_tags
  project     = var.project
  function    = "backend-check-failure"
  sqs_policy  = "failure_queue"
  kms_key_id  = module.encryption_key.kms_key_arn
}

module "antivirus_sqs_queue" {
  source                   = "./tdr-terraform-modules/sqs"
  common_tags              = local.common_tags
  project                  = var.project
  function                 = "antivirus"
  sqs_policy               = "file_checks"
  dead_letter_queue        = module.backend_check_failure_sqs_queue.sqs_arn
  redrive_maximum_receives = 3
  visibility_timeout       = local.file_check_lambda_timeouts_in_seconds["antivirus"] * 3
  kms_key_id               = module.encryption_key.kms_key_arn
}

module "download_files_sqs_queue" {
  source                   = "./tdr-terraform-modules/sqs"
  common_tags              = local.common_tags
  project                  = var.project
  function                 = "download-files"
  sns_topic_arns           = [module.dirty_upload_sns_topic.sns_arn]
  sqs_policy               = "sns_topic"
  dead_letter_queue        = module.backend_check_failure_sqs_queue.sqs_arn
  redrive_maximum_receives = 3
  visibility_timeout       = local.file_check_lambda_timeouts_in_seconds["download_files"] * 3
  kms_key_id               = module.encryption_key.kms_key_arn
}

module "checksum_sqs_queue" {
  source                   = "./tdr-terraform-modules/sqs"
  common_tags              = local.common_tags
  project                  = var.project
  function                 = "checksum"
  sqs_policy               = "file_checks"
  dead_letter_queue        = module.backend_check_failure_sqs_queue.sqs_arn
  redrive_maximum_receives = 3
  visibility_timeout       = local.file_check_lambda_timeouts_in_seconds["checksum"] * 3
  kms_key_id               = module.encryption_key.kms_key_arn
}

module "file_format_sqs_queue" {
  source                   = "./tdr-terraform-modules/sqs"
  common_tags              = local.common_tags
  project                  = var.project
  function                 = "file-format"
  sqs_policy               = "file_checks"
  dead_letter_queue        = module.backend_check_failure_sqs_queue.sqs_arn
  redrive_maximum_receives = 3
  visibility_timeout       = local.file_check_lambda_timeouts_in_seconds["file_format"] * 3
  kms_key_id               = module.encryption_key.kms_key_arn
}

module "api_update_queue" {
  source                   = "./tdr-terraform-modules/sqs"
  common_tags              = local.common_tags
  project                  = var.project
  function                 = "api-update"
  sqs_policy               = "api_update_antivirus"
  dead_letter_queue        = module.backend_check_failure_sqs_queue.sqs_arn
  redrive_maximum_receives = 3
  visibility_timeout       = local.file_check_lambda_timeouts_in_seconds["api_update"] * 3
  kms_key_id               = module.encryption_key.kms_key_arn
}

module "transform_engine_retry_queue" {
  source             = "./tdr-terraform-modules/sqs"
  common_tags        = local.common_tags
  project            = var.project
  function           = "transform-engine-retry"
  sqs_policy         = "transform_engine_retry"
  visibility_timeout = 180 * 3
  kms_key_id         = module.encryption_key.kms_key_arn
}

module "api_update_lambda" {
  source                                = "./tdr-terraform-modules/lambda"
  project                               = var.project
  common_tags                           = local.common_tags
  lambda_api_update                     = true
  timeout_seconds                       = local.file_check_lambda_timeouts_in_seconds["api_update"]
  auth_url                              = local.keycloak_auth_url
  api_url                               = module.consignment_api.api_url
  keycloak_backend_checks_client_secret = module.keycloak_ssm_parameters.params[local.keycloak_backend_checks_secret_name].value
  kms_key_arn                           = module.encryption_key.kms_key_arn
  private_subnet_ids                    = module.backend_checks_efs.private_subnets
  vpc_id                                = module.shared_vpc.vpc_id
}

module "file_format_lambda" {
  source                                 = "./tdr-terraform-modules/lambda"
  project                                = var.project
  common_tags                            = local.common_tags
  lambda_file_format                     = true
  timeout_seconds                        = local.file_check_lambda_timeouts_in_seconds["file_format"]
  file_system_id                         = module.backend_checks_efs.file_system_id
  backend_checks_efs_access_point        = module.backend_checks_efs.access_point
  vpc_id                                 = module.shared_vpc.vpc_id
  use_efs                                = true
  backend_checks_efs_root_directory_path = module.backend_checks_efs.root_directory_path
  private_subnet_ids                     = module.backend_checks_efs.private_subnets
  mount_target_zero                      = module.backend_checks_efs.mount_target_zero
  mount_target_one                       = module.backend_checks_efs.mount_target_one
  kms_key_arn                            = module.encryption_key.kms_key_arn
  efs_security_group_id                  = module.backend_checks_efs.security_group_id
}

module "download_files_lambda" {
  source                                 = "./tdr-terraform-modules/lambda"
  common_tags                            = local.common_tags
  project                                = var.project
  lambda_download_files                  = true
  timeout_seconds                        = local.file_check_lambda_timeouts_in_seconds["download_files"]
  s3_sns_topic                           = module.dirty_upload_sns_topic.sns_arn
  file_system_id                         = module.backend_checks_efs.file_system_id
  backend_checks_efs_access_point        = module.backend_checks_efs.access_point
  vpc_id                                 = module.shared_vpc.vpc_id
  use_efs                                = true
  auth_url                               = local.keycloak_auth_url
  api_url                                = module.consignment_api.api_url
  backend_checks_efs_root_directory_path = module.backend_checks_efs.root_directory_path
  private_subnet_ids                     = module.backend_checks_efs.private_subnets
  backend_checks_client_secret           = module.keycloak_ssm_parameters.params[local.keycloak_backend_checks_secret_name].value
  kms_key_arn                            = module.encryption_key.kms_key_arn
  efs_security_group_id                  = module.backend_checks_efs.security_group_id
  reserved_concurrency                   = 3
}

module "service_unavailable_lambda" {
  source                     = "./tdr-terraform-modules/lambda"
  project                    = var.project
  common_tags                = local.common_tags
  lambda_service_unavailable = true
  vpc_id                     = module.shared_vpc.vpc_id
  private_subnet_ids         = module.backend_checks_efs.private_subnets
}

module "backend_checks_efs" {
  source                       = "./tdr-terraform-modules/efs"
  common_tags                  = local.common_tags
  function                     = "backend-checks-efs"
  project                      = var.project
  access_point_path            = "/backend-checks"
  policy                       = "efs_access_policy"
  policy_roles                 = jsonencode(flatten([module.file_format_build_task.file_format_build_role, module.checksum_lambda.checksum_lambda_role, module.antivirus_lambda.antivirus_lambda_role, module.download_files_lambda.download_files_lambda_role, module.file_format_lambda.file_format_lambda_role]))
  bastion_role                 = module.bastion_role.role.arn
  mount_target_security_groups = flatten([module.file_format_lambda.file_format_lambda_sg_id, module.download_files_lambda.download_files_lambda_sg_id, module.file_format_build_task.file_format_build_sg_id, module.antivirus_lambda.antivirus_lambda_sg_id, module.checksum_lambda.checksum_lambda_sg_id])
  nat_gateway_ids              = module.shared_vpc.nat_gateway_ids
  vpc_cidr_block               = module.shared_vpc.vpc_cidr_block
  vpc_id                       = module.shared_vpc.vpc_id
}

module "file_format_build_task" {
  source            = "./tdr-terraform-modules/ecs"
  common_tags       = local.common_tags
  file_system_id    = module.backend_checks_efs.file_system_id
  access_point      = module.backend_checks_efs.access_point
  file_format_build = true
  project           = var.project
  vpc_id            = module.shared_vpc.vpc_id
}

module "export_api" {
  source          = "./tdr-terraform-modules/apigateway"
  api_name        = "ExportAPI"
  api_template    = "export_api"
  template_params = { lambda_arn = module.export_authoriser_lambda.export_api_authoriser_arn, state_machine_arn = module.export_step_function.state_machine_arn }
  environment     = local.environment
  common_tags     = local.common_tags
}

module "signed_cookies_api" {
  source          = "./tdr-terraform-modules/apigateway"
  api_name        = "SignedCookiesAPI"
  api_template    = "sign_cookies_api"
  template_params = { lambda_arn = module.sign_cookies_lambda.sign_cookies_arn, upload_cors_urls = module.frontend.frontend_url }
  environment     = local.environment
  common_tags     = local.common_tags
}

module "export_authoriser_lambda" {
  source                   = "./tdr-terraform-modules/lambda"
  common_tags              = local.common_tags
  project                  = "tdr"
  lambda_export_authoriser = true
  timeout_seconds          = 10
  api_url                  = module.consignment_api.api_url
  api_gateway_arn          = module.export_api.api_arn
  kms_key_arn              = module.encryption_key.kms_key_arn
  private_subnet_ids       = module.backend_checks_efs.private_subnets
  vpc_id                   = module.shared_vpc.vpc_id
  efs_security_group_id    = module.backend_checks_efs.security_group_id

}

module "sign_cookies_lambda" {
  source                 = "./tdr-terraform-modules/lambda"
  common_tags            = local.common_tags
  project                = "tdr"
  lambda_sign_cookies    = true
  auth_url               = local.keycloak_auth_url
  frontend_url           = module.frontend.frontend_url
  upload_domain          = local.upload_domain
  cloudfront_key_pair_id = module.cloudfront_upload.cloudfront_key_pair_id
  timeout_seconds        = 60
  api_gateway_arn        = module.signed_cookies_api.api_arn
  kms_key_arn            = module.encryption_key.kms_key_arn
  private_subnet_ids     = module.backend_checks_efs.private_subnets
  vpc_id                 = module.shared_vpc.vpc_id
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
  source                 = "./tdr-terraform-modules/stepfunctions"
  project                = var.project
  common_tags            = local.common_tags
  definition             = "consignment_export"
  environment            = local.environment
  step_function_name     = "ConsignmentExport"
  definition_variables   = { security_groups = jsonencode([module.consignment_export_ecs_security_group.security_group_id]), subnet_ids = jsonencode(module.export_efs.private_subnets), cluster_arn = module.consignment_export_ecs_task.cluster_arn, task_arn = module.consignment_export_ecs_task.task_definition_arn, task_name = "consignment-export", sns_topic = module.notifications_topic.sns_arn }
  policy                 = "consignment_export"
  policy_variables       = { task_arn = module.consignment_export_ecs_task.task_definition_arn, execution_role = module.consignment_export_execution_role.role.arn, task_role = module.consignment_export_task_role.role.arn, kms_key_arn = module.encryption_key.kms_key_arn }
  notification_sns_topic = module.notifications_topic.sns_arn
}

module "export_bucket" {
  source      = "./tdr-terraform-modules/s3"
  project     = var.project
  function    = "consignment-export"
  common_tags = local.common_tags
}

module "export_bucket_judgment" {
  source      = "./tdr-terraform-modules/s3"
  project     = var.project
  function    = "consignment-export-judgment"
  common_tags = local.common_tags
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
  event_rule_arns                = []
  sns_topic_arns                 = [module.notifications_topic.sns_arn]
  muted_scan_alerts              = module.global_parameters.muted_ecr_scan_alerts
  judgment_export_s3_bucket_name = module.export_bucket_judgment.s3_bucket_name
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
  subnet_ids  = flatten([module.backend_checks_efs.private_subnets, module.export_efs.private_subnets, module.shared_vpc.private_subnets])
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
  source             = "./tdr-terraform-modules/iam_role"
  assume_role_policy = templatefile("./tdr-terraform-modules/ec2/templates/ec2_assume_role.json.tpl", {})
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
      antivirus_role         = module.antivirus_lambda.antivirus_lambda_role[0],
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
  kms_key_arn                      = module.encryption_key.kms_key_arn
  auth_url                         = local.keycloak_auth_url
  vpc_id                           = module.shared_vpc.vpc_id
  lambda_create_keycloak_user_api  = true
  private_subnet_ids               = module.backend_checks_efs.private_subnets
  keycloak_user_management_api_arn = module.create_keycloak_users_api.api_arn
}

module "create_keycloak_users_s3_lambda" {
  source                         = "./tdr-terraform-modules/lambda"
  common_tags                    = local.common_tags
  project                        = var.project
  user_admin_client_secret       = module.keycloak_ssm_parameters.params[local.keycloak_user_admin_client_secret_name].value
  kms_key_arn                    = module.encryption_key.kms_key_arn
  auth_url                       = local.keycloak_auth_url
  vpc_id                         = module.shared_vpc.vpc_id
  lambda_create_keycloak_user_s3 = true
  private_subnet_ids             = module.backend_checks_efs.private_subnets
  s3_bucket_arn                  = module.create_bulk_users_bucket.s3_bucket_arn
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
