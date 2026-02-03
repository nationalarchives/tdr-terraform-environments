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

variable "read_client_secret_path" {}

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

variable "block_skip_metadata_review" {}

variable "block_legal_status" {}

variable "draft_metadata_validator_api_url" {}

variable "draft_metadata_s3_kms_keys" {}

variable "draft_metadata_s3_bucket_name" {}

variable "notification_sns_topic_arn" {}

variable "encryption_kms_key_arn" {}

variable "aws_guardduty_ecr_arn" {}

variable "enable_wiz_sensor" {}

variable "s3_acl_header_value" {}

variable "s3_if_none_match_header_value" {}

variable "transit_encryption_mode" {
  description = "Set to preferred(default) or required.  Must be set to preferred and applied before required (if wanted)"
  default     = "required"
}

variable "metadata_version_override" {
  description = "metadata schema version override. File name prefix"
  type        = string
}

