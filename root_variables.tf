variable "workspace_to_environment_map" {
  type = map(string)

  //Maps the Terraform workspace to the AWS environment.
  default = {
    ci   = "ci"
    test = "test"
    prod = "prod"
  }
}
