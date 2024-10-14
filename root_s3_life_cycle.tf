locals {
  // Apply to intg /staging environments only initially
  life_cycle_count        = local.environment == "prod" ? 0 : 1
  dirty_bucket_expiration = local.environment == "prod" ? 7 : 1
}

resource "aws_s3_bucket_lifecycle_configuration" "upload_file_cloudfront_dirty_s3" {
  count  = local.life_cycle_count
  bucket = module.upload_file_cloudfront_dirty_s3.s3_bucket_id
  rule {
    id     = "delete-backend-checks-completed"
    status = "Enabled"
    filter {
      tag {
        key   = "BackendChecks"
        value = "Completed"
      }
    }
    expiration {
      days = local.dirty_bucket_expiration
    }
  }
}
