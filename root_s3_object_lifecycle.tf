locals {
  default_expiration_days = local.environment == "prod" ? 30 : 7

  backend_checks_bucket_policy_status = "Enabled"
  clean_bucket_policy_status          = local.environment == "prod" ? "Disabled" : "Enabled"
  dirty_bucket_policy_status          = local.environment == "prod" ? "Disabled" : "Enabled"
  export_bucket_policy_status         = local.environment == "prod" ? "Disabled" : "Enabled"
  quarantine_bucket_policy_status     = local.environment == "prod" ? "Disabled" : "Enabled"

  backend_checks_results_bucket_lifecycle_rules = [{
    id     = "delete-backend-checks-results-bucket-objects"
    status = local.backend_checks_bucket_policy_status
    expiration = {
      days = local.default_expiration_days
    }
    noncurrent_version_expiration = {
      noncurrent_days = local.default_expiration_days
    }
  }]

  clean_bucket_lifecycle_rules = [
    {
      id     = "delete-clean-bucket-objects"
      status = local.clean_bucket_policy_status
      expiration = {
        days = local.default_expiration_days
      }
      noncurrent_version_expiration = {
        noncurrent_days = local.default_expiration_days
      }
  }]

  dirty_bucket_lifecycle_rules = [
    {
      id     = "delete-dirty-bucket-objects"
      status = local.dirty_bucket_policy_status
      expiration = {
        days = local.default_expiration_days
      }
      noncurrent_version_expiration = {
        noncurrent_days = local.default_expiration_days
      }
  }]

  export_bucket_lifecycle_rules = [
    {
      id     = "delete-export-bucket-objects"
      status = local.export_bucket_policy_status
      expiration = {
        days = local.default_expiration_days
      }
      noncurrent_version_expiration = {
        noncurrent_days = local.default_expiration_days
      }
  }]

  quarantine_bucket_lifecycle_rules = [
    {
      id     = "delete-quarantine-bucket-objects"
      status = local.quarantine_bucket_policy_status
      expiration = {
        days = local.default_expiration_days
      }
      noncurrent_version_expiration = {
        noncurrent_days = local.default_expiration_days
      }
  }]
}
