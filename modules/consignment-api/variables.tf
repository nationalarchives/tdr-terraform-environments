variable "alb_dns_name" {}

variable "alb_target_group_arn" {}

variable "alb_zone_id" {}

variable "app_name" {}

variable "auth_url" {}

variable "frontend_url" {}

variable "block_http4s" {}

variable "da_reference_generator_url" {}

variable "common_tags" {}

variable "database_availability_zones" {}

variable "db_migration_sg" {}

variable "dns_zone_id" {}

variable "environment" {}

variable "environment_full_name" {}

variable "kms_key_id" {}

variable "private_subnets" {}

variable "backend_checks_subnets" {}

variable "public_subnets" {}

variable "region" {}

variable "vpc_id" {}

variable "dns_zone_name_trimmed" {}

variable "ip_allowlist" {
  description = "IP addresses allowed to access"
  default     = ["0.0.0.0/0"]
}

variable "create_users_security_group_id" {
  type = list(string)
}

variable "db_instance_resource_id" {}

variable "block_assign_file_references" {}
