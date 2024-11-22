terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.76.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 5.12"
    }
  }
  required_version = ">= 1.9.8"
}
