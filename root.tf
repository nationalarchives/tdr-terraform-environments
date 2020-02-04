locals {
  environment = terraform.workspace
  assume_role = "arn:aws:iam::${var.tdr_account_number}:role/TDRTerraformRole${title(local.environment)}"
  environment_full_name_map = {
    "intg"    = "integration",
    "staging" = "staging",
    "prod"    = "production"
  }
  common_tags = map(
    "Environment", local.environment,
    "Owner", "TDR",
    "Terraform", true
  )
  database_availability_zones = ["eu-west-2a", "eu-west-2b"]
  region                      = "eu-west-2"
}

terraform {
  backend "s3" {
    bucket         = "tdr-terraform-state"
    key            = "terraform.state"
    region         = "eu-west-2"
    encrypt        = true
    dynamodb_table = "tdr-terraform-state-lock"
  }
}

provider "aws" {
  region = "eu-west-2"
  assume_role {
    role_arn     = local.assume_role
    session_name = "terraform"
  }
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
  db_user         = module.consignment_api.database_username
  db_password     = module.consignment_api.database_password
}

module "consignment_api" {
  source                      = "./modules/consignment-api"
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
}

module "frontend" {
  app_name              = "frontend"
  source                = "./modules/transfer-frontend"
  environment           = local.environment
  environment_full_name = local.environment_full_name_map[local.environment]
  common_tags           = local.common_tags
  region                = local.region
  vpc_id                = module.shared_vpc.vpc_id
  public_subnets        = module.shared_vpc.public_subnets
  private_subnets       = module.shared_vpc.private_subnets
}

module "keycloak" {
  app_name                    = "keycloak"
  source                      = "./modules/keycloak"
  environment                 = local.environment
  environment_full_name       = local.environment_full_name_map[local.environment]
  common_tags                 = local.common_tags
  database_availability_zones = local.database_availability_zones
  az_count                    = 2
  region                      = local.region
}
