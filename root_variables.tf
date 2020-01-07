variable "tdr_account_number" {
  description = "The AWS account number where the TDR environment is hosted"
  type        = string
}

variable "tdr_environment" {
  description = "The TDR environment"
  type        = string
  default     = "intg"
}
