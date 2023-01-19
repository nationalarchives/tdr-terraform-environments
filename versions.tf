terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.50.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 5.12"
    }
  }
  required_version = ">= 1.3.2"
}
