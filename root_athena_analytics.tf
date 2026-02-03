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
  source             = "./da-terraform-modules/athena"
  name               = "tdr_reporting_analytics"
  result_bucket_name = local.athena_results_bucket_name
  create_table_queries = {
    metadata_validation_reports = templatefile("${path.module}/templates/athena/metadata_validation_reports.sql.tpl", {
      bucket_name = local.athena_metadata_checks_database_name
    })
  }
  common_tags = local.common_tags
  kms_key_arn = module.s3_internal_kms_key.kms_key_arn

  depends_on = [module.athena_reporting_results_s3]
}

data "aws_iam_policy_document" "athena_analytics_policy_document" {
  statement {
    actions = [
      "athena:StartQueryExecution",
      "athena:StopQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:GetWorkGroup"
    ]
    resources = [
      module.athena_reporting_analytics.workgroup_arn
    ]
  }
}

module "athena_analytics_policy" {
  source        = "./da-terraform-modules/iam_policy"
  name          = "TDRAthenaAnalyticsPolicy${title(local.environment)}"
  policy_string = data.aws_iam_policy_document.athena_analytics_policy_document.json
}
