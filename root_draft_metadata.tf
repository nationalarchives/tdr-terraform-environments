locals {
  draft_metadata_bucket_name = "${var.project}-draft-metadata-${local.environment}"
}

module "draft_metadata_validator_lambda" {
  source        = "./da-terraform-modules/lambda"
  function_name = "tdr-draft-metadata-validator-${local.environment}"
  handler       = "uk.gov.nationalarchives.draftmetadatavalidator.Lambda::handleRequest"
  runtime       = local.runtime_java_11
  tags          = local.common_tags
  timeout       = 120
  memory_size   = 1024
  policies = {
    "TDRDraftMetadataValidatorLambdaPolicy${title(local.environment)}" = templatefile("./templates/iam_policy/draft_metadata_validator_lambda.json.tpl", {
      account_id     = var.tdr_account_number
      environment    = local.environment
      parameter_name = local.keycloak_backend_checks_secret_name
      bucket_name    = local.draft_metadata_bucket_name
      kms_key_arn    = module.s3_internal_kms_key.kms_key_arn
    })
  }
  plaintext_env_vars = {
    API_URL            = "${module.consignment_api.api_url}/graphql"
    AUTH_URL           = local.keycloak_auth_url
    CLIENT_SECRET_PATH = local.keycloak_backend_checks_secret_name
    BUCKET_NAME        = local.draft_metadata_bucket_name
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
  bucket_name = local.draft_metadata_bucket_name
  common_tags = local.common_tags
  kms_key_arn = module.s3_internal_kms_key.kms_key_arn
}
