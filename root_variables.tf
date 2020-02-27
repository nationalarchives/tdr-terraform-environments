variable "tdr_account_number" {
  description = "The AWS account number where the TDR environment is hosted"
  type        = string
}

variable "dns_zone" {
  description = "DNS zone name e.g. tdr-management.nationalarchives.gov.uk"
  default = "tdr-management.nationalarchives.gov.uk"
}

variable "function" {
  description = "forms the second part of the bucket name, eg. upload"
  default = "jenkins"
}

variable "project" {
  description = "abbreviation for the project, e.g. tdr, forms the first part of resource names"
  default = "tdr"
}