variable "environment" {}
variable "vpc_id" {}
variable "common_tags" {}
variable "private_subnets" {}
variable "db_url" {}
variable "db_instance_id" {}
variable "lambda_java_runtimes" {
  description = "Java runtime versions used by Lambda functions"
  type        = map(string)
}
