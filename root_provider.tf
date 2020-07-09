provider "aws" {
  region  = "eu-west-2"
  version = 2.69

  assume_role {
    role_arn     = local.assume_role
    session_name = "terraform"
  }
}
