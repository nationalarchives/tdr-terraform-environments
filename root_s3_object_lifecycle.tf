locals {
  default_expiration_days = local.environment == "prod" ? 30 : 7

  backend_checks_bucket_policy_status = "Enabled"

  dirty_bucket_policy_status = local.environment == "intg" ? "Enabled" : "Disabled"

  dirty_bucket_lifecycle_rules = [
    {
      id     = "delete-dirty-buckets-objects"
      status = local.dirty_bucket_policy_status
      expiration = {
        days = local.default_expiration_days
      }
      noncurrent_version_expiration = {
        noncurrent_days = local.default_expiration_days
      }
  }]
}

resource "aws_s3_bucket_lifecycle_configuration" "backend_checks_results_s3_bucket" {
  bucket = module.backend_lambda_function_bucket.s3_bucket_id
  rule {
    id     = "delete-backend-checks-results-bucket-objects"
    status = local.backend_checks_bucket_policy_status
    expiration {
      days = local.default_expiration_days
    }
    noncurrent_version_expiration {
      noncurrent_days = local.default_expiration_days
    }
  }
}
