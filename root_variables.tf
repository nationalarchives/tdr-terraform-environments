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