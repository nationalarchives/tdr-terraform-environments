variable "tdr_account_number" {
  description = "The AWS account number where the TDR environment is hosted"
  type        = string
}

variable "project" {
  description = "abbreviation for the project, e.g. tdr, forms the first part of resource names"
  default     = "tdr"
}

variable "geo_match" {
  description = "countries to allow through web application firewall in csv format"
  default     = "GB"
}

variable "domain" {
  description = "domain, e.g. example.com"
  default     = "nationalarchives.gov.uk"
}

variable "admin_sso_internal_access_manually_enabled" {
  description = "grants admin SSO access to internal s3 bucket KMS key. Managed by add_admin workflow"
  type = bool
  default = false
}

variable "admin_sso_export_access_manually_enabled" {
  description = "grants admin SSO access to export s3 bucket KMS key. Managed by add_admin workflow"
  type = bool
  default = false
}
