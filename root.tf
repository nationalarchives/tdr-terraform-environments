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
  auth_url                       = module.keycloak.auth_url
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
  auth_url              = module.keycloak.auth_url
  client_secret_path    = module.keycloak.client_secret_path
  export_api_url        = module.export_api.api_url
  alb_id                = module.frontend_alb.alb_id
  public_subnet_ranges  = module.shared_vpc.public_subnet_ranges
}

module "keycloak" {
  app_name                      = "keycloak"
  source                        = "./modules/keycloak"
  alb_dns_name                  = module.keycloak_alb.alb_dns_name
  alb_target_group_arn          = module.keycloak_alb.alb_target_group_arn
  alb_zone_id                   = module.keycloak_alb.alb_zone_id
  dns_zone_id                   = local.dns_zone_id
  dns_zone_name_trimmed         = local.dns_zone_name_trimmed
  environment                   = local.environment
  environment_full_name         = local.environment_full_name_map[local.environment]
  common_tags                   = local.common_tags
  database_availability_zones   = local.database_availability_zones
  az_count                      = 2
  region                        = local.region
  frontend_url                  = module.frontend.frontend_url
  kms_key_id                    = module.encryption_key.kms_key_arn
  create_user_security_group_id = module.create_keycloak_db_users_lambda.create_keycloak_user_lambda_security_group
  notification_sns_topic        = module.notifications_topic.sns_arn
  kms_key_arn                   = module.encryption_key.kms_key_arn
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

module "upload_file_dirty_s3" {
  source                   = "./tdr-terraform-modules/s3"
  project                  = var.project
  function                 = "upload-files-dirty"
  common_tags              = local.common_tags
  cors_urls                = local.upload_cors_urls
  sns_notification         = true
  abort_incomplete_uploads = true
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

module "keycloak_alb" {
  source                = "./tdr-terraform-modules/alb"
  project               = var.project
  function              = "keycloak"
  environment           = local.environment
  alb_log_bucket        = module.alb_logs_s3.s3_bucket_id
  alb_security_group_id = module.keycloak.alb_security_group_id
  alb_target_group_port = 8080
  alb_target_type       = "ip"
  certificate_arn       = module.keycloak_certificate.certificate_arn
  health_check_matcher  = "200,303"
  health_check_path     = ""
  http_listener         = false
  public_subnets        = module.keycloak.public_subnets
  vpc_id                = module.keycloak.vpc_id
  common_tags           = local.common_tags
  own_host_header_only  = true
  host                  = module.keycloak.auth_host
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
  source      = "./tdr-terraform-modules/kms"
  project     = var.project
  function    = "encryption"
  key_policy  = "message_system_access"
  environment = local.environment
  common_tags = local.common_tags
}

module "waf" {
  # a single WAF web acl and rules are used for all services to minimise AWS costs
  # uses AWS classic WAF - should upgrade to WAFv2 once supported by Terraform
  source            = "./tdr-terraform-modules/waf"
  project           = var.project
  function          = "apps"
  environment       = local.environment
  common_tags       = local.common_tags
  alb_target_groups = [module.keycloak_alb.alb_arn, module.consignment_api_alb.alb_arn, module.frontend_alb.alb_arn]
  trusted_ips       = concat(local.ip_allowlist, list("${module.shared_vpc.nat_gateway_public_ips[0]}/32", "${module.shared_vpc.nat_gateway_public_ips[1]}/32"))
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

module "create_keycloak_db_users_lambda" {
  source                           = "./tdr-terraform-modules/lambda"
  project                          = var.project
  common_tags                      = local.common_tags
  lambda_create_keycloak_db_users  = true
  vpc_id                           = module.keycloak.vpc_id
  private_subnet_ids               = module.keycloak.private_subnets
  db_admin_user                    = module.keycloak.db_username
  db_admin_password                = module.keycloak.db_password
  db_url                           = module.keycloak.db_url
  kms_key_arn                      = module.encryption_key.kms_key_arn
  keycloak_password                = module.keycloak.keycloak_user_password
  keycloak_database_security_group = module.keycloak.database_security_group
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

module "api_update_lambda" {
  source                                = "./tdr-terraform-modules/lambda"
  project                               = var.project
  common_tags                           = local.common_tags
  lambda_api_update                     = true
  timeout_seconds                       = local.file_check_lambda_timeouts_in_seconds["api_update"]
  auth_url                              = module.keycloak.auth_url
  api_url                               = module.consignment_api.api_url
  keycloak_backend_checks_client_secret = module.keycloak.backend_checks_client_secret
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
  auth_url                               = module.keycloak.auth_url
  api_url                                = module.consignment_api.api_url
  backend_checks_efs_root_directory_path = module.backend_checks_efs.root_directory_path
  private_subnet_ids                     = module.backend_checks_efs.private_subnets
  backend_checks_client_secret           = module.keycloak.backend_checks_client_secret
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
  auth_url               = module.keycloak.auth_url
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
  policy_roles                 = jsonencode(module.export_task.consignment_export_task_role_arn)
  mount_target_security_groups = flatten([module.export_task.consignment_export_sg_id])
  bastion_role                 = module.bastion_role.role.arn
  netnum_offset                = 6
  nat_gateway_ids              = module.shared_vpc.nat_gateway_ids
  vpc_cidr_block               = module.shared_vpc.vpc_cidr_block
  vpc_id                       = module.shared_vpc.vpc_id
}

module "export_task" {
  source                     = "./tdr-terraform-modules/ecs"
  common_tags                = local.common_tags
  project                    = var.project
  consignment_export         = true
  file_system_id             = module.export_efs.file_system_id
  access_point               = module.export_efs.access_point
  backend_client_secret_path = module.keycloak.backend_checks_client_secret_path
  clean_bucket               = module.upload_bucket.s3_bucket_name
  output_bucket              = module.export_bucket.s3_bucket_name
  api_url                    = module.consignment_api.api_url
  auth_url                   = module.keycloak.auth_url
  vpc_id                     = module.shared_vpc.vpc_id
}

module "export_step_function" {
  source                 = "./tdr-terraform-modules/stepfunctions"
  project                = var.project
  common_tags            = local.common_tags
  definition             = "consignment_export"
  environment            = local.environment
  step_function_name     = "ConsignmentExport"
  definition_variables   = { security_groups = jsonencode(module.export_task.consignment_export_sg_id), subnet_ids = jsonencode(module.export_efs.private_subnets), cluster_arn = module.export_task.consignment_export_cluster_arn, task_arn = module.export_task.consignment_export_task_arn, task_name = "consignment-export", sns_topic = module.notifications_topic.sns_arn }
  policy                 = "consignment_export"
  policy_variables       = { task_arn = module.export_task.consignment_export_task_arn, execution_role = module.export_task.consignment_export_execution_role_arn, task_role = module.export_task.consignment_export_task_role_arn, kms_key_arn = module.encryption_key.kms_key_arn }
  notification_sns_topic = module.notifications_topic.sns_arn
}

module "export_bucket" {
  source      = "./tdr-terraform-modules/s3"
  project     = var.project
  function    = "consignment-export"
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
  source                        = "./tdr-terraform-modules/lambda"
  common_tags                   = local.common_tags
  project                       = "tdr"
  lambda_ecr_scan_notifications = true
  event_rule_arns               = []
  sns_topic_arns                = [module.notifications_topic.sns_arn]
  muted_scan_alerts             = module.global_parameters.muted_ecr_scan_alerts
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

module "keycloak_public_nacl" {
  source = "./tdr-terraform-modules/nacl"
  name   = "keycloak-public-nacl-${local.environment}"
  vpc_id = module.keycloak.vpc_id
  ingress_rules = [
    { rule_no = 100, cidr_block = "0.0.0.0/0", action = "allow", from_port = 443, to_port = 443, egress = false },
    { rule_no = 200, cidr_block = "0.0.0.0/0", action = "allow", from_port = 1024, to_port = 65535, egress = false },
    { rule_no = 100, cidr_block = "0.0.0.0/0", action = "allow", from_port = 443, to_port = 443, egress = true },
    { rule_no = 200, cidr_block = "0.0.0.0/0", action = "allow", from_port = 1024, to_port = 65535, egress = true },
  ]
  subnet_ids  = module.keycloak.public_subnets
  common_tags = local.common_tags
}

module "keycloak_private_nacl" {
  source = "./tdr-terraform-modules/nacl"
  name   = "keycloak-private-nacl-${local.environment}"
  vpc_id = module.keycloak.vpc_id
  ingress_rules = [
    # The task needs a port to communicate with ssm over the internet but I can't find which one so all ephemeral ports need to be open to the internet
    # Using a VPC endpoint for SSM should allow us to restrict this to traffic inside the VPC
    { rule_no = 100, cidr_block = "0.0.0.0/0", action = "allow", from_port = 1024, to_port = 65535, egress = false },
    { rule_no = 200, cidr_block = "0.0.0.0/0", action = "allow", from_port = 443, to_port = 443, egress = false },
    { rule_no = 100, cidr_block = "0.0.0.0/0", action = "allow", from_port = 443, to_port = 443, egress = true },
    { rule_no = 200, cidr_block = module.keycloak.vpc_cidr_block, action = "allow", from_port = 1024, to_port = 65535, egress = true }
  ]
  subnet_ids  = module.keycloak.private_subnets
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
    { rule_no = 200, cidr_block = module.keycloak.vpc_cidr_block, action = "allow", from_port = 1024, to_port = 65535, egress = true }
  ]
  subnet_ids  = flatten([module.backend_checks_efs.private_subnets, module.export_efs.private_subnets, module.shared_vpc.private_subnets])
  common_tags = local.common_tags
}

module "tdr_default_nacl" {
  source                 = "./tdr-terraform-modules/default_nacl"
  default_network_acl_id = module.shared_vpc.default_nacl_id
}

module "keycloak_default_nacl" {
  source                 = "./tdr-terraform-modules/default_nacl"
  default_network_acl_id = module.keycloak.default_nacl_id
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

module "keycloak_cloudwatch" {
  source      = "./tdr-terraform-modules/cloudwatch_logs"
  common_tags = local.common_tags
  name        = "/ecs/keycloak-auth-${local.environment}"
}

module "keycloak_ecs_execution_policy" {
  source        = "./tdr-terraform-modules/iam_policy"
  name          = "KeycloakECSExecutionPolicy${title(local.environment)}"
  policy_string = templatefile("./tdr-terraform-modules/iam_policy/templates/keycloak_ecs_execution_policy.json.tpl", { cloudwatch_log_group = module.keycloak_cloudwatch.log_group_arn, ecr_account_number = local.ecr_account_number })
}

module "keycloak_ecs_task_policy" {
  source        = "./tdr-terraform-modules/iam_policy"
  name          = "KeycloakECSTaskPolicy${title(local.environment)}"
  policy_string = templatefile("./tdr-terraform-modules/iam_policy/templates/keycloak_ecs_task_role_policy.json.tpl", { account_id = data.aws_caller_identity.current.account_id, environment = local.environment, kms_arn = module.encryption_key.kms_key_arn })
}

module "keycloak_execution_role" {
  source             = "./tdr-terraform-modules/iam_role"
  assume_role_policy = templatefile("./tdr-terraform-modules/ecs/templates/ecs_assume_role_policy.json.tpl", {})
  common_tags        = local.common_tags
  name               = "KeycloakECSExecutionRole${title(local.environment)}"
  policy_attachments = {
    ssm_policy       = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess",
    execution_policy = module.keycloak_ecs_execution_policy.policy_arn
  }
}

module "keycloak_task_role" {
  source             = "./tdr-terraform-modules/iam_role"
  assume_role_policy = templatefile("./tdr-terraform-modules/ecs/templates/ecs_assume_role_policy.json.tpl", {})
  common_tags        = local.common_tags
  name               = "KeycloakECSTaskRole${title(local.environment)}"
  policy_attachments = { task_policy = module.keycloak_ecs_task_policy.policy_arn }
}

module "keycloak_ssm_parameters" {
  source      = "./tdr-terraform-modules/ssm_parameter"
  common_tags = local.common_tags
  random_parameters = [
    { name = local.keycloak_backend_checks_secret_name, description = "The Keycloak backend checks secret", value = random_uuid.backend_checks_client_secret.result, type = "SecureString" },
    { name = local.keycloak_tdr_client_secret_name, description = "The Keycloak tdr client secret", value = random_uuid.client_secret.result, type = "SecureString" },
    { name = local.keycloak_user_password_name, description = "The Keycloak user password", value = random_password.keycloak_password.result, type = "SecureString" },
    { name = local.keycloak_admin_password_name, description = "The Keycloak admin password", value = random_password.password.result, type = "SecureString" },
    { name = local.keycloak_govuk_notify_api_key_name, description = "The GovUK Notify API key", value = "to_be_manually_added", type = "SecureString" },
    { name = local.keycloak_govuk_notify_template_id_name, description = "The GovUK Notify Template ID", value = "to_be_manually_added", type = "SecureString" }
  ]
  parameters = [
    { name = local.keycloak_admin_user_name, description = "The Keycloak admin user", value = "tdr-keycloak-admin-${local.environment}", type = "SecureString" },
    { name = local.keycloak_configuration_properties_name, description = "The Keycloak configuration properties file ", value = "${local.environment}_properties.json", type = "SecureString" },
    { name = local.keycloak_user_admin_client_secret_name, description = "The Keycloak user admin secret", value = random_uuid.backend_checks_client_secret.result, type = "SecureString" },
    { name = local.keycloak_reporting_client_secret_name, description = "The Keycloak reporting client secret", value = random_uuid.reporting_client_secret.result, type = "SecureString" },
    { name = local.keycloak_realm_admin_client_secret_name, description = "The Keycloak realm admin secret", value = random_uuid.backend_checks_client_secret.result, type = "SecureString" }
  ]
}

module "keycloak_ecs_security_group" {
  source      = "./tdr-terraform-modules/security_group"
  description = "Controls access within our network for the Keycloak ECS Task"
  name        = "tdr-keycloak-ecs-security-group"
  vpc_id      = module.shared_vpc.vpc_id
  common_tags = local.common_tags
  ingress_security_group_rules = [
    { port = 8080, security_group_id = module.keycloak_alb_security_group.security_group_id, description = "Allow the load balancer to access the task" }
  ]
  egress_cidr_rules = [{ port = 0, cidr_blocks = ["0.0.0.0/0"], description = "Allow outbound access on all ports", protocol = "-1" }]
}

module "keycloak_alb_security_group" {
  source      = "./tdr-terraform-modules/security_group"
  description = "Controls access to the keycloak load balancer"
  name        = "keycloak-load-balancer-security-group"
  vpc_id      = module.shared_vpc.vpc_id
  common_tags = local.common_tags
  ingress_cidr_rules = [
    { port = 443, cidr_blocks = ["0.0.0.0/0"], description = "Allow all IPs over HTTPS" }
  ]
  egress_cidr_rules = [{ port = 0, cidr_blocks = ["0.0.0.0/0"], description = "Allow outbound access on all ports", protocol = "-1" }]
}

module "keycloak_database_security_group" {
  source      = "./tdr-terraform-modules/security_group"
  description = "Controls access to the keycloak database"
  name        = "keycloak-database-security-group-${local.environment}"
  vpc_id      = module.shared_vpc.vpc_id
  common_tags = local.common_tags
  ingress_security_group_rules = [
    { port = 5432, security_group_id = module.keycloak_ecs_security_group.security_group_id, description = "Allow Postgres port from the ECS task" },
    { port = 5432, security_group_id = module.create_keycloak_db_users_lambda_new.create_keycloak_user_lambda_security_group_new[0], description = "Allow Postgres port from the create user lambda" }
  ]
  egress_security_group_rules = [{ port = 5432, security_group_id = module.keycloak_ecs_security_group.security_group_id, description = "Allow Postgres port from the ECS task", protocol = "-1" }]
}

module "tdr_keycloak" {
  source               = "./tdr-terraform-modules/generic_ecs"
  alb_target_group_arn = module.keycloak_tdr_alb.alb_target_group_arn
  cluster_name         = "keycloak_new_${local.environment}"
  common_tags          = local.common_tags
  container_definition = templatefile("${path.module}/templates/ecs_tasks/keycloak.json.tpl", {
    app_image                         = "${local.ecr_account_number}.dkr.ecr.eu-west-2.amazonaws.com/auth-server:${local.environment}"
    app_port                          = 8080
    app_environment                   = local.environment
    aws_region                        = local.region
    url_path                          = module.keycloak_database.db_url_parameter_name
    username                          = "keycloak_user"
    password_path                     = local.keycloak_user_password_name
    admin_user_path                   = local.keycloak_admin_user_name
    admin_password_path               = local.keycloak_admin_password_name
    client_secret_path                = local.keycloak_tdr_client_secret_name
    backend_checks_client_secret_path = local.keycloak_backend_checks_secret_name
    realm_admin_client_secret_path    = local.keycloak_realm_admin_client_secret_name
    frontend_url                      = module.frontend.frontend_url
    configuration_properties_path     = local.keycloak_configuration_properties_name
    user_admin_client_secret_path     = local.keycloak_user_admin_client_secret_name
    govuk_notify_api_key_path         = local.keycloak_govuk_notify_api_key_name
    govuk_notify_template_id_path     = local.keycloak_govuk_notify_template_id_name
    reporting_client_secret_path      = local.keycloak_reporting_client_secret_name
    sns_topic_arn                     = module.notifications_topic.sns_arn
  })
  container_name               = "keycloak"
  cpu                          = 1024
  environment                  = local.environment
  execution_role               = module.keycloak_execution_role.role.arn
  load_balancer_container_port = 8080
  memory                       = 3072
  private_subnets              = module.shared_vpc.private_subnets
  security_groups              = [module.keycloak_ecs_security_group.security_group_id]
  service_name                 = "keycloak_${local.environment}"
  task_family_name             = "keycloak-${local.environment}"
  task_role                    = module.keycloak_task_role.role.arn
}

module "keycloak_tdr_alb" {
  source                = "./tdr-terraform-modules/alb"
  project               = var.project
  function              = "keycloak-new"
  environment           = local.environment
  alb_log_bucket        = module.alb_logs_s3.s3_bucket_id
  alb_security_group_id = module.keycloak_alb_security_group.security_group_id
  alb_target_group_port = 8080
  alb_target_type       = "ip"
  certificate_arn       = module.keycloak_certificate.certificate_arn
  health_check_matcher  = "200,303"
  health_check_path     = ""
  http_listener         = false
  public_subnets        = module.shared_vpc.public_subnets
  vpc_id                = module.shared_vpc.vpc_id
  common_tags           = local.common_tags
  own_host_header_only  = true
  host                  = "auth.tdr-${local.environment_full_name}.nationalarchives.gov.uk" //Will set this correctly in another PR when we move the DNS over
}

module "keycloak_database" {
  source                      = "./tdr-terraform-modules/rds"
  admin_username              = "keycloak_admin"
  common_tags                 = local.common_tags
  database_availability_zones = local.database_availability_zones
  database_name               = "keycloak"
  environment                 = local.environment
  kms_key_id                  = module.encryption_key.kms_key_arn
  private_subnets             = module.shared_vpc.private_subnets
  security_group_ids          = [module.keycloak_database_security_group.security_group_id]
}

module "create_keycloak_db_users_lambda_new" {
  source                              = "./tdr-terraform-modules/lambda"
  project                             = var.project
  common_tags                         = local.common_tags
  lambda_create_keycloak_db_users_new = true
  vpc_id                              = module.shared_vpc.vpc_id
  private_subnet_ids                  = module.shared_vpc.private_subnets
  db_admin_user                       = module.keycloak_database.db_username
  db_admin_password                   = module.keycloak_database.db_password
  db_url                              = module.keycloak_database.db_url
  kms_key_arn                         = module.encryption_key.kms_key_arn
  keycloak_password                   = module.keycloak_ssm_parameters.params[local.keycloak_user_password_name].value
  keycloak_database_security_group    = module.keycloak_database_security_group.security_group_id
}
