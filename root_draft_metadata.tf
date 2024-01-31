module "draft_metadata_validator_lambda" {
  source        = "./da-terraform-modules/lambda"
  function_name = "tdr-draft-metadata-validator-${local.environment}"
  handler       = "draft_metadata_validator.handler"
  runtime       = local.runtime_java_11
  tags          = local.common_tags
  policies = {
    "TDRDraftMetadataValidatorLambdaPolicy${title(local.environment)}" = templatefile("./templates/iam_policy/draft_metadata_validator_lambda.json.tpl", {
      account_id  = var.tdr_account_number
      environment = local.environment
    })
  }
}

module "draft_metadata_api_gateway" {
  source = "./da-terraform-modules/apigateway"
  api_definition = templatefile("./templates/api_gateway/draft_metadata.json.tpl", {
    environment           = local.environment
    title                 = "Draft Metadata"
    lambda_arn            = module.draft_metadata_validator_lambda.lambda_arn,
    region                = local.region
    authoriser_lambda_arn = module.export_authoriser_lambda.export_api_authoriser_arn
  })
  api_name    = "DraftMetadata"
  environment = local.environment
  common_tags = local.common_tags
}

module "draft_metadata_bucket" {
  source      = "./da-terraform-modules/s3"
  bucket_name = "${var.project}-draft-metadata-${local.environment_domain}"
  common_tags = local.common_tags
  kms_key_arn = module.s3_internal_kms_key.kms_key_arn
}
