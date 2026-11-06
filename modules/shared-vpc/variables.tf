variable "environment" {}
variable "common_tags" {}
variable "az_count" {}
variable "database_availability_zones" {}
variable "aws_guardduty_ecr_arn" {
  description = "ARN of the AWS owned ECR repository holding the GuardDuty Fargate runtime monitoring agent image"
}
variable "cloudwatch_retention_period_days" {
  description = "Retention period in days for the cloudwatch log group where flow logs are kept"
  default     = 30
}

