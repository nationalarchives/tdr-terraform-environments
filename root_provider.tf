provider "aws" {
  region = "eu-west-2"

  assume_role {
    role_arn     = local.assume_role
    session_name = "terraform"
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = "useast1"

  assume_role {
    role_arn     = local.assume_role
    session_name = "terraform"
  }
}

provider "github" {
  owner = "nationalarchives"
}