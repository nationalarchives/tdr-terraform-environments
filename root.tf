locals {
  #Ensure that developers' workspaces always default to 'dev'
  environment = terraform.workspace
  aws_region = "eu-west-2"
  availability_zones =  ["eu-west-2a", "eu-west-2b"]
  common_tags = map(
  "Environment", local.environment,
  "Owner", "TDR",
  "Terraform", true
  )
}

terraform {
  backend "s3" {
    bucket = "tdr-terraform-state"
    key = "tdr-terraform.state"
    region = "eu-west-2"
    encrypt = true
    dynamodb_table = "tdr-terraform-state-lock"
  }
}

provider "aws" {
  region = local.aws_region
}

module "keycloak" {
  app_name = "keycloak"
  source = "./modules/keycloak"
  environment = local.environment
  common_tags = local.common_tags
  database_availability_zones = local.availability_zones
  az_count = 2
  region = "eu-west-2"
}

