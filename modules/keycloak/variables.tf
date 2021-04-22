variable "alb_dns_name" {}

variable "alb_target_group_arn" {}

variable "alb_zone_id" {}

variable "app_name" {}

variable "az_count" {}

variable "common_tags" {}

variable "database_availability_zones" {}

variable "dns_zone_id" {}

variable "dns_zone_name_trimmed" {}

variable "environment" {}

variable "environment_full_name" {}

variable "region" {}

variable "frontend_url" {}

variable "ip_whitelist" {
  description = "IP addresses allowed to access"
  default     = ["0.0.0.0/0"]
}

variable "kms_key_id" {
  description = "KMS ID for the database encryption key"
}

variable "create_user_security_group_id" {
  default = ""
}
