locals {
  #Ensure that developers' workspaces always default to 'intg'

  environment         = lookup(var.workspace_to_environment_map, terraform.workspace, "intg")
  environment_profile = lookup(var.workspace_aws_profile_map, terraform.workspace, "intg")

  common_tags = map(
    "Environment", local.environment,
    "Owner", "TDR",
    "Terraform", true
  )
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
  region  = "eu-west-2"
  assume_role {
    role_arn = "arn:aws:iam::229554778675:role/TDRTerraformRoleIntg"
    session_name = "terraform"
  }
}


module "frontend" {
  app_name                    = "frontend"
  source                      = "./modules/transfer-frontend"
  environment                 = local.environment
  common_tags                 = local.common_tags
  database_availability_zones = ["eu-west-2a", "eu-west-2b"]
  az_count                    = 2
  region                      = "eu-west-2"
}

module "keycloak" {
  app_name                    = "keycloak"
  source                      = "./modules/keycloak"
  environment                 = local.environment
  common_tags                 = local.common_tags
  database_availability_zones = ["eu-west-2a", "eu-west-2b"]
  az_count                    = 2
  region                      = "eu-west-2"
}
