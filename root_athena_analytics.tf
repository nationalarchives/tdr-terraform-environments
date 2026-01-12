module "athena_results_bucket" {
  source      = "./da-terraform-modules/s3"
  bucket_name = local.athena_results_bucket_name
  kms_key_arn = module.s3_external_kms_key.kms_key_arn
  common_tags = local.common_tags
  lifecycle_rules = local.environment == "prod" ? [] : local.non_prod_default_bucket_lifecycle_rules
}

module "athena_data_bucket" {
  source      = "./da-terraform-modules/s3"
  bucket_name = local.athena_data_bucket_name
  kms_key_arn = module.s3_external_kms_key.kms_key_arn
  common_tags = local.common_tags
  bucket_policy = templatefile("${path.module}/templates/s3/allow_read_access.json.tpl", {
    bucket_name           = local.athena_data_bucket_name
    read_access_roles     = []  # Add roles as needed
    aws_backup_local_role = local.aws_back_up_local_role
  })
  lifecycle_rules = local.environment == "prod" ? [] : local.non_prod_default_bucket_lifecycle_rules
  s3_data_bucket_additional_tags = local.aws_back_up_tags
}

module "athena_reporting_analytics" {
  source = "./da-terraform-modules/athena"
  name   = "tdr-reporting-analytics"
  result_bucket_name = local.athena_results_bucket_name
  create_table_queries = {}
  common_tags = local.common_tags
  kms_key_arn = module.s3_external_kms_key.kms_key_arn
}
