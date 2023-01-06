terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.72.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 5.12"
    }
  }
  required_version = ">= 1.3.2"
}
