locals {
  #Ensure that developers' workspaces always default to 'ci'
  environment = lookup(var.workspace_to_environment_map, terraform.workspace, "ci")
  common_tags = map(
    "Environment", local.environment,
    "Owner", "TDR",
    "Terraform", true
  )
}

terraform {
  backend "s3" {
    bucket         = "tdr-terraform-state"
    key            = "prototype-terraform.state"
    region         = "eu-west-2"
    encrypt        = true
    dynamodb_table = "tdr-terraform-state-lock"
  }
}

data "aws_ssm_parameter" "account_number" {
  name = "/mgmt/${local.environment}_account"
}

provider "aws" {
  region      = "eu-west-2"
  assume_role {
    role_arn = "arn:aws:iam::${data.aws_ssm_parameter.account_number.value}:role/${local.environment}-terraform-role"
  }
  profile     = "managementprofile"
}

//Create s3 bucket to test setup is working
resource "aws_s3_bucket" "tk_test_bucket" {
  bucket        = "tk-test-bucket3"
  acl           = "private"
  force_destroy = true

  tags = merge(
    map(
      //local.common_tags,
      "Name", "to-be-deleted",
    )
  )
}