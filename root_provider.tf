provider "aws" {
  region = "eu-west-2"

  assume_role {
    role_arn     = local.terraform_role
    session_name = "terraform"
    external_id  = module.global_parameters.external_ids.terraform_environments
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = "useast1"

  assume_role {
    role_arn     = local.terraform_role
    session_name = "terraform"
    external_id  = module.global_parameters.external_ids.terraform_environments
  }
}

provider "aws" {
  region = "eu-west-2"
  alias  = "alarm_deployer"

  assume_role {
    role_arn = local.terraform_role_alarm_deployer
  }
}

provider "github" {
  owner = "nationalarchives"
}
