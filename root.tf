locals {
  #Ensure that developers' workspaces always default to 'ci'
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
  profile = local.environment_profile
}
