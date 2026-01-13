module "athena_metadata_checks_s3" {
  source      = "./da-terraform-modules/s3"
  bucket_name = local.athena_metadata_checks_database_name
  kms_key_arn = module.s3_internal_kms_key.kms_key_arn
  common_tags = local.common_tags
}

module "athena_reporting_results_s3" {
  source      = "./da-terraform-modules/s3"
  bucket_name = local.athena_results_bucket_name
  common_tags = local.common_tags
  kms_key_arn = module.s3_internal_kms_key.kms_key_arn
}

module "athena_reporting_analytics" {
  source = "./da-terraform-modules/athena"
  name   = "tdr_reporting_analytics"
  result_bucket_name = local.athena_results_bucket_name
  create_table_queries = {
    metadata_validation_reports = templatefile("${path.module}/templates/athena/metadata_validation_reports.sql.tpl", {
      bucket_name = local.athena_metadata_checks_database_name
    })
  }
  common_tags = local.common_tags
  kms_key_arn =  module.s3_internal_kms_key.kms_key_arn
}
