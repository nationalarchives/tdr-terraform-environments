terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.4"
    }
    github = {
      source  = "integrations/github"
      version = "~> 5.12"
    }
  }
  required_version = ">= 1.12.2"
}
