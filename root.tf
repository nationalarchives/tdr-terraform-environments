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
  db_user         = module.consignment_api.database_username
  db_password     = module.consignment_api.database_password
}

module "consignment_api" {
  source                      = "./modules/consignment-api"
  dns_zone_id                 = local.dns_zone_id
  alb_dns_name                = module.consignment_api_alb.alb_dns_name
  alb_target_group_arn        = module.consignment_api_alb.alb_target_group_arn
  alb_zone_id                 = module.consignment_api_alb.alb_zone_id
  app_name                    = "consignmentapi"
  common_tags                 = local.common_tags
  database_availability_zones = local.database_availability_zones
  environment                 = local.environment
  environment_full_name       = local.environment_full_name_map[local.environment]
  private_subnets             = module.shared_vpc.private_subnets
  public_subnets              = module.shared_vpc.public_subnets
  vpc_id                      = module.shared_vpc.vpc_id
  region                      = local.region
  db_migration_sg             = module.database_migrations.db_migration_security_group
  auth_url                    = module.keycloak.auth_url
  kms_key_id                  = module.encryption_key.kms_key_arn
  frontend_url                = module.frontend.frontend_url
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
  region                = local.region
  vpc_id                = module.shared_vpc.vpc_id
  public_subnets        = module.shared_vpc.public_subnets
  private_subnets       = module.shared_vpc.private_subnets
  dns_zone_name_trimmed = local.dns_zone_name_trimmed
  auth_url              = module.keycloak.auth_url
  client_secret_path    = module.keycloak.client_secret_path
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
  source            = "./tdr-terraform-modules/s3"
  project           = var.project
  function          = "upload-files"
  common_tags       = local.common_tags
  version_lifecycle = true
}

module "upload_bucket_quarantine" {
  source      = "./tdr-terraform-modules/s3"
  project     = var.project
  function    = "upload-files-quarantine"
  common_tags = local.common_tags
}

module "upload_file_dirty_s3" {
  source            = "./tdr-terraform-modules/s3"
  project           = var.project
  function          = "upload-files-dirty"
  common_tags       = local.common_tags
  cors              = true
  frontend_url      = module.frontend.frontend_url
  version_lifecycle = true
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
  trusted_ips       = split(",", data.aws_ssm_parameter.trusted_ips.value)
  geo_match         = split(",", var.geo_match)
  restricted_uri    = "auth/admin"
}

module "backend_lambda_function_bucket" {
  source = "./tdr-terraform-modules/s3"
  common_tags = local.common_tags
  function = "backend-checks"
  project = var.project
}

module "av_lambda" {
  source            = "./tdr-terraform-modules/lambda"
  project = var.project
  function = "yara-av"
  environment = local.environment
  common_tags = local.common_tags
  handler = "matcher.matcher_lambda_handler"
  runtime = "python3.7"
  policy = "av_lambda"
  lambda_subnets = module.shared_vpc.private_subnets
  vpc_id = module.shared_vpc.vpc_id
}
