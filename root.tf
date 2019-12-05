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
    dynamodb_table = "tdr-terraform-statelock"
  }
}

provider "aws" {
  region = local.aws_region
}

module "database" {
  source = "./modules/database"
  environment = local.environment
  common_tags = local.common_tags
  database_availability_zones = local.availability_zones
  security_group_ids = []
  subnet_group_name =  "subnet"
}

