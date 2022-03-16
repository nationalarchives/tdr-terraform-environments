provider "aws" {
  region = "eu-west-2"
}

provider "aws" {
  region = "us-east-1"
  alias  = "useast1"
}

provider "github" {
  owner = "nationalarchives"
}
