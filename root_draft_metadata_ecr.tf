module "draft_metadata_validator_lambda_ecr" {
  source          = "./da-terraform-modules/lambda"
  function_name   = "tdr-draft-metadata-validator-v2-${local.environment}"
  handler         = "uk.gov.nationalarchives.draftmetadatavalidator.Lambda::handleRequest"
  tags            = local.common_tags
  use_image       = true
  image_url       = "arn:aws:ecr:eu-west-2:${data.aws_ssm_parameter.mgmt_account_number.value}:repository/draft-metadata-validator"
  timeout_seconds = 120
  memory_size     = 1024
  policies = {
    "TDRDraftMetadataValidatorLambdaPolicyECR${title(local.environment)}" = templatefile("./templates/iam_policy/draft_metadata_validator_lambda.json.tpl", {
      account_id     = var.tdr_account_number
      environment    = local.environment
      parameter_name = local.keycloak_backend_checks_secret_name
      bucket_name    = local.draft_metadata_s3_bucket_name
      kms_key_arn    = module.s3_internal_kms_key.kms_key_arn
    })
  }
  plaintext_env_vars = {
    API_URL            = "${module.consignment_api.api_url}/graphql"
    AUTH_URL           = local.keycloak_auth_url
    CLIENT_SECRET_PATH = local.keycloak_backend_checks_secret_name
    BUCKET_NAME        = local.draft_metadata_s3_bucket_name
  }
}
