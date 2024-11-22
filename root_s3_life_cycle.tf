locals {
  delete_object_tag_key      = "Delete"
  delete_object_tag_value    = "True"
  clean_buckets              = [module.upload_bucket]
  clean_bucket_expiration    = local.environment == "prod" ? 30 : 7
  clean_bucket_policy_status = "Disabled"

  dirty_buckets              = [module.upload_file_cloudfront_dirty_s3]
  dirty_bucket_expiration    = local.environment == "prod" ? 7 : 1
  dirty_bucket_policy_status = local.environment == "intg" ? "Enabled" : "Disabled"

  export_buckets              = [module.export_bucket, module.flat_format_export_bucket]
  export_bucket_expiration    = local.environment == "prod" ? 30 : 7
  export_bucket_policy_status = "Disabled"
}

resource "aws_s3_bucket_lifecycle_configuration" "dirty_s3_buckets" {
  for_each = { for bucket in local.dirty_buckets : bucket.s3_bucket_name => bucket }
  bucket   = each.value.s3_bucket_id
  rule {
    id     = "delete-dirty-buckets-objects"
    status = local.dirty_bucket_policy_status
    filter {
      tag {
        key   = local.delete_object_tag_key
        value = local.delete_object_tag_value
      }
    }
    expiration {
      days = local.dirty_bucket_expiration
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "clean_s3_buckets" {
  for_each = { for bucket in local.clean_buckets : bucket.s3_bucket_name => bucket }
  bucket   = each.value.s3_bucket_id
  rule {
    id     = "delete-clean-buckets-objects"
    status = local.clean_bucket_policy_status
    filter {
      tag {
        key   = local.delete_object_tag_key
        value = local.delete_object_tag_value
      }
    }
    expiration {
      days = local.clean_bucket_expiration
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "export_s3_buckets" {
  for_each = { for bucket in local.export_buckets : bucket.s3_bucket_name => bucket }
  bucket   = each.value.s3_bucket_id
  rule {
    id     = "delete-export-buckets-objects"
    status = local.export_bucket_policy_status
    filter {
      tag {
        key   = local.delete_object_tag_key
        value = local.delete_object_tag_value
      }
    }
    expiration {
      days = local.export_bucket_expiration
    }
  }
}
