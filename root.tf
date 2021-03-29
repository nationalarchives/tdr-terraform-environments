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
  create_users_security_group_id = module.create_db_users_lambda.create_users_lambda_security_group_id
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
  ip_whitelist          = local.environment == "intg" ? local.ip_whitelist : ["0.0.0.0/0"]
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
  app_name                    = "keycloak"
  source                      = "./modules/keycloak"
  alb_dns_name                = module.keycloak_alb.alb_dns_name
  alb_target_group_arn        = module.keycloak_alb.alb_target_group_arn
  alb_zone_id                 = module.keycloak_alb.alb_zone_id
  dns_zone_id                 = local.dns_zone_id
  dns_zone_name_trimmed       = local.dns_zone_name_trimmed
  environment                 = local.environment
  environment_full_name       = local.environment_full_name_map[local.environment]
  common_tags                 = local.common_tags
  database_availability_zones = local.database_availability_zones
  az_count                    = 2
  region                      = local.region
  frontend_url                = module.frontend.frontend_url
  kms_key_id                  = module.encryption_key.kms_key_arn
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
  sns_topic_arn            = module.dirty_upload_sns_topic.sns_arn
  sns_notification         = true
  abort_incomplete_uploads = true
}

module "consignment_api_certificate" {
  source      = "./tdr-terraform-modules/certificatemanager"
  project     = var.project
  function    = "consignment-api"
  dns_zone    = local.environment_domain
  domain_name = "api.${local.environment_domain}"
  common_tags = local.common_tags
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
  domain_name           = "api.${local.dns_zone_name_trimmed}"
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
  domain_name           = "auth.${local.dns_zone_name_trimmed}"
  health_check_matcher  = "200,303"
  health_check_path     = ""
  http_listener         = false
  public_subnets        = module.keycloak.public_subnets
  vpc_id                = module.keycloak.vpc_id
  common_tags           = local.common_tags
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
  domain_name           = local.dns_zone_name_trimmed
  health_check_matcher  = "200,303"
  health_check_path     = ""
  public_subnets        = module.shared_vpc.public_subnets
  vpc_id                = module.shared_vpc.vpc_id
  common_tags           = local.common_tags
}

module "encryption_key" {
  source      = "./tdr-terraform-modules/kms"
  project     = var.project
  key_policy  = "lambda"
  function    = "encryption"
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
  trusted_ips       = concat(split(",", data.aws_ssm_parameter.trusted_ips.value), list("${module.shared_vpc.nat_gateway_public_ips[0]}/32", "${module.shared_vpc.nat_gateway_public_ips[1]}/32"))
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
  project                                = var.project
  use_efs                                = true
  vpc_id                                 = module.shared_vpc.vpc_id
  private_subnet_ids                     = module.backend_checks_efs.private_subnets
  mount_target_zero                      = module.backend_checks_efs.mount_target_zero
  mount_target_one                       = module.backend_checks_efs.mount_target_one
  kms_key_arn                            = module.encryption_key.kms_key_arn
}

module "checksum_lambda" {
  source                                 = "./tdr-terraform-modules/lambda"
  project                                = var.project
  common_tags                            = local.common_tags
  lambda_checksum                        = true
  file_system_id                         = module.backend_checks_efs.file_system_id
  backend_checks_efs_access_point        = module.backend_checks_efs.access_point
  vpc_id                                 = module.shared_vpc.vpc_id
  use_efs                                = true
  backend_checks_efs_root_directory_path = module.backend_checks_efs.root_directory_path
  private_subnet_ids                     = module.backend_checks_efs.private_subnets
  mount_target_zero                      = module.backend_checks_efs.mount_target_zero
  mount_target_one                       = module.backend_checks_efs.mount_target_one
  kms_key_arn                            = module.encryption_key.kms_key_arn
}

module "create_db_users_lambda" {
  source                     = "./tdr-terraform-modules/lambda"
  project                    = var.project
  common_tags                = local.common_tags
  lambda_create_db_users     = true
  vpc_id                     = module.shared_vpc.vpc_id
  private_subnet_ids         = module.backend_checks_efs.private_subnets
  consignment_database_sg_id = module.consignment_api.consignment_db_security_group_id
  db_admin_user              = module.consignment_api.database_username
  db_admin_password          = module.consignment_api.database_password
  db_url                     = module.consignment_api.database_url
  kms_key_arn                = module.encryption_key.kms_key_arn
}

module "dirty_upload_sns_topic" {
  source      = "./tdr-terraform-modules/sns"
  common_tags = local.common_tags
  project     = var.project
  function    = "s3-dirty-upload"
  sns_policy  = "s3_upload"
}

module "backend_check_failure_sqs_queue" {
  source      = "./tdr-terraform-modules/sqs"
  common_tags = local.common_tags
  project     = var.project
  function    = "backend-check-failure"
}

module "antivirus_sqs_queue" {
  source                   = "./tdr-terraform-modules/sqs"
  common_tags              = local.common_tags
  project                  = var.project
  function                 = "antivirus"
  dead_letter_queue        = module.backend_check_failure_sqs_queue.sqs_arn
  redrive_maximum_receives = 3
  visibility_timeout       = 180
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
  visibility_timeout       = 180
}

module "checksum_sqs_queue" {
  source                   = "./tdr-terraform-modules/sqs"
  common_tags              = local.common_tags
  project                  = var.project
  function                 = "checksum"
  sqs_policy               = "sns_topic"
  dead_letter_queue        = module.backend_check_failure_sqs_queue.sqs_arn
  redrive_maximum_receives = 3
  visibility_timeout       = 180
}

module "file_format_sqs_queue" {
  source                   = "./tdr-terraform-modules/sqs"
  common_tags              = local.common_tags
  project                  = var.project
  function                 = "file-format"
  dead_letter_queue        = module.backend_check_failure_sqs_queue.sqs_arn
  redrive_maximum_receives = 3
  // Terraform will fail if the visibility timeout is shorter than the lambda timeout.
  // The timeout for the file format lambda is set to 900 seconds, more than the other backend check lambdas because the file format lambda is slower than the others
  visibility_timeout = 900
}

module "api_update_queue" {
  source                   = "./tdr-terraform-modules/sqs"
  common_tags              = local.common_tags
  project                  = var.project
  function                 = "api-update"
  sqs_policy               = "api_update_antivirus"
  dead_letter_queue        = module.backend_check_failure_sqs_queue.sqs_arn
  redrive_maximum_receives = 3
}

module "api_update_lambda" {
  source                                = "./tdr-terraform-modules/lambda"
  project                               = var.project
  common_tags                           = local.common_tags
  lambda_api_update                     = true
  auth_url                              = module.keycloak.auth_url
  api_url                               = module.consignment_api.api_url
  keycloak_backend_checks_client_secret = module.keycloak.backend_checks_client_secret
  kms_key_arn                           = module.encryption_key.kms_key_arn
}

module "file_format_lambda" {
  source                                 = "./tdr-terraform-modules/lambda"
  project                                = var.project
  common_tags                            = local.common_tags
  lambda_file_format                     = true
  file_system_id                         = module.backend_checks_efs.file_system_id
  backend_checks_efs_access_point        = module.backend_checks_efs.access_point
  vpc_id                                 = module.shared_vpc.vpc_id
  use_efs                                = true
  backend_checks_efs_root_directory_path = module.backend_checks_efs.root_directory_path
  private_subnet_ids                     = module.backend_checks_efs.private_subnets
  mount_target_zero                      = module.backend_checks_efs.mount_target_zero
  mount_target_one                       = module.backend_checks_efs.mount_target_one
  kms_key_arn                            = module.encryption_key.kms_key_arn
}

module "download_files_lambda" {
  source                                 = "./tdr-terraform-modules/lambda"
  common_tags                            = local.common_tags
  project                                = var.project
  lambda_download_files                  = true
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
}

module "backend_checks_efs" {
  source                       = "./tdr-terraform-modules/efs"
  common_tags                  = local.common_tags
  function                     = "backend-checks-efs"
  project                      = var.project
  access_point_path            = "/backend-checks"
  policy                       = "backend_checks_access_policy"
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

module "export_authoriser_lambda" {
  source                   = "./tdr-terraform-modules/lambda"
  common_tags              = local.common_tags
  project                  = "tdr"
  lambda_export_authoriser = true
  api_url                  = module.consignment_api.api_url
  api_gateway_arn          = module.export_api.api_arn
  kms_key_arn              = module.encryption_key.kms_key_arn
}

//create a new efs volume, ECS task attached to the volume and pass in the proper variables and create ECR repository in the backend project

module "export_efs" {
  source                       = "./tdr-terraform-modules/efs"
  common_tags                  = local.common_tags
  function                     = "export-efs"
  project                      = var.project
  access_point_path            = "/export"
  policy                       = "export_access_policy"
  mount_target_security_groups = flatten([module.export_task.consignment_export_sg_id])
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
  policy_variables       = { task_arn = module.export_task.consignment_export_task_arn, execution_role = module.export_task.consignment_export_execution_role_arn, task_role = module.export_task.consignment_export_task_role_arn }
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
}
