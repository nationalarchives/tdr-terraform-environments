variable "workspace_to_environment_map" {
  type = map(string)

  //Maps the Terraform workspace to the AWS environment.
  default = {
    intg    = "intg"
    staging = "staging"
    prod    = "prod"
  }
}

variable "workspace_aws_profile_map" {
  type = map(string)

  default = {
    intg    = "intgterraform"
    staging = "stagingterraform"
    prod    = "prodterraform"
  }
}

variable "account_number" {
  type = string
}
