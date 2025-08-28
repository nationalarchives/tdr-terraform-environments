locals {
  default_expiration_days          = local.environment == "prod" ? 30 : 7
  default_non_prod_expiration_days = 30

  backend_checks_bucket_policy_status = "Enabled"
  dirty_bucket_policy_status          = local.environment == "prod" ? "Disabled" : "Enabled"
  export_bucket_policy_status         = local.environment == "prod" ? "Disabled" : "Enabled"

  object_tag_dr2_ingest_key            = "PreserveDigitalAssetIngest"
  object_tag_dr2_ingest_value_complete = "Complete"

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

  non_prod_default_bucket_lifecycle_rules = [
    {
      id     = "delete-bucket-objects"
      status = "Enabled"
      expiration = {
        days = local.default_non_prod_expiration_days
      }
      noncurrent_version_expiration = {
        noncurrent_days = local.default_non_prod_expiration_days
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
      filter = {
        tag = {
          key   = local.object_tag_dr2_ingest_key
          value = local.object_tag_dr2_ingest_value_complete
        }
      }
      noncurrent_version_expiration = {
        noncurrent_days = local.default_expiration_days
      }
  }]
}
