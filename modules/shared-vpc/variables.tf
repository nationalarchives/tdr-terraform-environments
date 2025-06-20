variable "environment" {}
variable "common_tags" {}
variable "az_count" {}
variable "database_availability_zones" {}
variable "cloudwatch_retention_period_days" {
  description = "Retention period in days for the cloudwatch log group where flow logs are kept"
  default     = 30
}

