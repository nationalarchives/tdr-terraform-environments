variable "alb_dns_name" {}

variable "alb_target_group_arn" {}

variable "alb_zone_id" {}

variable "app_name" {}

variable "common_tags" {}

variable "dns_zone_id" {}

variable "environment" {}

variable "environment_full_name" {}

variable "private_subnets" {}

variable "public_subnets" {}

variable "region" {}

variable "vpc_id" {}

variable "dns_zone_name_trimmed" {}

variable "auth_url" {}

variable "client_secret_path" {}

variable "ip_allowlist" {
  description = "IP addresses allowed to access"
  default     = ["0.0.0.0/0"]
}

variable "export_api_url" {}

variable "backend_checks_api_url" {}

variable "otel_service_name" {}

variable "alb_id" {}

variable "public_subnet_ranges" {
  type = list(string)
}

variable "block_validation_library" {}

variable "block_draft_metadata_upload" {}
