variable "environment" {}
variable "common_tags" {}
variable "az_count" {}
variable "database_availability_zones" {}
variable "cloudwatch_rentention_period" {
  description = "Rentention period for the cloudwatch log group where flow logs are kept"
  default     = 30
}

