module "draft_metadata_validator_lambda" {
  source          = "./da-terraform-modules/lambda"
  function_name   = "tdr-draft-metadata-validator-${local.environment}"
  tags            = local.common_tags
  use_image       = true
  image_url       = "${data.aws_ssm_parameter.mgmt_account_number.value}.dkr.ecr.eu-west-2.amazonaws.com/draft-metadata-validator:${local.environment}"
  timeout_seconds = 240
  memory_size     = 1024
  policies = {
    "TDRDraftMetadataValidatorLambdaPolicy${title(local.environment)}" = templatefile("./templates/iam_policy/draft_metadata_validator_lambda.json.tpl", {
      account_id         = var.tdr_account_number
      environment        = local.environment
      parameter_name     = local.keycloak_tdr_draft_metadata_client_secret_name
      bucket_name        = local.draft_metadata_s3_bucket_name
      kms_key_arn        = module.s3_internal_kms_key.kms_key_arn
      ecr_account_number = local.ecr_account_number
    })
  }
  plaintext_env_vars = {
    API_URL            = "${module.consignment_api.api_url}/graphql"
    AUTH_URL           = local.keycloak_auth_url
    CLIENT_SECRET_PATH = local.keycloak_tdr_draft_metadata_client_secret_name
    BUCKET_NAME        = local.draft_metadata_s3_bucket_name
  }
}

module "draft_metadata_persistence_lambda" {
  source          = "./da-terraform-modules/lambda"
  function_name   = "tdr-draft-metadata-persistence-${local.environment}"
  handler         = "uk.gov.nationalarchives.tdr.draftmetadatapersistence.Lambda::handleRequest"
  runtime         = local.runtime_java_21
  tags            = local.common_tags
  timeout_seconds = 240
  memory_size     = 1024
  policies = {
    "TDRDraftMetadataPersistenceLambdaPolicy${title(local.environment)}" = templatefile("./templates/iam_policy/draft_metadata_persistence_lambda.json.tpl", {
      account_id     = var.tdr_account_number
      environment    = local.environment
      parameter_name = local.keycloak_tdr_draft_metadata_client_secret_name
      bucket_name    = local.draft_metadata_s3_bucket_name
      kms_key_arn    = module.s3_internal_kms_key.kms_key_arn
    })
  }
  plaintext_env_vars = {
    API_URL            = "${module.consignment_api.api_url}/graphql"
    AUTH_URL           = local.keycloak_auth_url
    CLIENT_SECRET_PATH = local.keycloak_tdr_draft_metadata_client_secret_name
    BUCKET_NAME        = local.draft_metadata_s3_bucket_name
  }
}

module "draft_metadata_checks_lambda" {
  source          = "./da-terraform-modules/lambda"
  function_name   = "tdr-draft-metadata-checks-${local.environment}"
  handler         = "uk.gov.nationalarchives.tdr.draftmetadatachecks.Lambda::handleRequest"
  runtime         = local.runtime_java_21
  tags            = local.common_tags
  timeout_seconds = 240
  memory_size     = 1024
  policies = {
    "TDRDraftMetadataValidationLambdaPolicy${title(local.environment)}" = templatefile("./templates/iam_policy/draft_metadata_checks_lambda.json.tpl", {
      account_id     = var.tdr_account_number
      environment    = local.environment
      parameter_name = local.keycloak_tdr_draft_metadata_client_secret_name
      bucket_name    = local.draft_metadata_s3_bucket_name
      kms_key_arn    = module.s3_internal_kms_key.kms_key_arn
    })
  }
  plaintext_env_vars = {
    API_URL            = "${module.consignment_api.api_url}/graphql"
    AUTH_URL           = local.keycloak_auth_url
    CLIENT_SECRET_PATH = local.keycloak_tdr_draft_metadata_client_secret_name
    BUCKET_NAME        = local.draft_metadata_s3_bucket_name
  }
}

module "draft_metadata_api_gateway" {
  source = "./da-terraform-modules/apigateway"
  api_definition = templatefile("./templates/api_gateway/draft_metadata.json.tpl", {
    environment           = local.environment
    title                 = "Draft Metadata"
    state_machine_arn     = module.draft_metadata_checks.step_function_arn
    execution_role_arn    = aws_iam_role.draft_metadata_api_gateway_execution_role.arn
    region                = local.region
    authoriser_lambda_arn = module.export_authoriser_lambda.export_api_authoriser_arn
  })
  api_name    = "DraftMetadata"
  environment = local.environment
  common_tags = local.common_tags
  api_method_settings = [{
    method_path        = "*/*"
    logging_level      = "INFO",
    metrics_enabled    = false,
    data_trace_enabled = false
  }]
}

resource "aws_iam_role" "draft_metadata_api_gateway_execution_role" {
  name               = "TDRMetadataChecksAPIGatewayExecutionRole${title(local.environment)}"
  assume_role_policy = templatefile("./templates/iam_policy/api_gateway_assume_role_policy.json.tpl", { account_id = data.aws_caller_identity.current.id })
}

resource "aws_iam_policy" "api_gateway_execution_policy" {
  name = "TDRMetadataChecksAPIGatewayStepFunctionExecutionPolicy${title(local.environment)}"
  policy = templatefile(
    "./templates/iam_policy/api_gateway_state_machine_policy.json.tpl",
    {
      account_id        = data.aws_caller_identity.current.account_id,
      state_machine_arn = module.draft_metadata_checks.step_function_arn
    }
  )
}

resource "aws_iam_role_policy_attachment" "api_gateway_execution_policy" {
  role       = aws_iam_role.draft_metadata_api_gateway_execution_role.name
  policy_arn = aws_iam_policy.api_gateway_execution_policy.arn
}

module "draft_metadata_bucket" {
  source      = "./da-terraform-modules/s3"
  bucket_name = local.draft_metadata_s3_bucket_name
  common_tags = local.common_tags
  kms_key_arn = module.s3_internal_kms_key.kms_key_arn
}

data "aws_ssm_parameter" "draft_metadata_keycloak_secret" {
  name            = local.keycloak_tdr_draft_metadata_client_secret_name
  with_decryption = true
}

resource "aws_cloudwatch_event_connection" "consignment_api_connection" {
  name               = "TDRConsignmentAPIConnection${title(local.environment)}"
  authorization_type = "OAUTH_CLIENT_CREDENTIALS"

  auth_parameters {
    oauth {
      client_parameters {
        client_id     = local.keycloak_draft-metadata_client_id
        client_secret = data.aws_ssm_parameter.draft_metadata_keycloak_secret.value
      }

      authorization_endpoint = "${local.keycloak_auth_url}/realms/tdr/protocol/openid-connect/token"
      http_method            = "POST"

      oauth_http_parameters {
        body {
          key             = "grant_type"
          value           = "client_credentials"
          is_value_secret = false
        }
      }
    }
  }
}

resource "aws_iam_policy" "draft_metadata_checks_policy" {
  name        = "TDRMetadataChecksPolicy${title(local.environment)}"
  description = "Policy to allow necessary lambda executions from step function and s3 access"

  policy = templatefile("./templates/iam_policy/metadata_checks_policy.json.tpl", {
    resources = jsonencode([
      module.yara_av_v2.lambda_arn,
      module.draft_metadata_validator_lambda.lambda_arn,
      module.draft_metadata_checks_lambda.lambda_arn,
      module.draft_metadata_persistence_lambda.lambda_arn
    ]),
    draft_metadata_bucket = local.draft_metadata_s3_bucket_name
    s3_kms_key_arn        = module.s3_internal_kms_key.kms_key_arn
    sns_kms_key_arn       = module.encryption_key.kms_key_arn
    account_id            = data.aws_caller_identity.current.account_id
    environment           = local.environment
  })
}

resource "aws_iam_policy" "api_invoke_policy" {
  name = "TDRAPIInvokePolicy${title(local.environment)}"

  policy = templatefile("./templates/iam_policy/third_party_api_invocation_template.json.tpl", {
    region            = local.region
    account_number    = var.tdr_account_number
    connection_arn    = aws_cloudwatch_event_connection.consignment_api_connection.arn
    api_url           = module.consignment_api.api_url
    step_function_arn = module.draft_metadata_checks.step_function_arn
  })
}

module "draft_metadata_checks" {
  source             = "./da-terraform-modules/sfn"
  step_function_name = "TDRMetadataChecks${title(local.environment)}"
  step_function_definition = templatefile("./templates/step_function/metadata_checks_definition.json.tpl", {
    antivirus_lambda_arn           = module.yara_av_v2.lambda_arn,
    consignment_api_url            = module.consignment_api.api_url,
    consignment_api_connection_arn = aws_cloudwatch_event_connection.consignment_api_connection.arn,
    checks_lambda_arn              = module.draft_metadata_checks_lambda.lambda_arn,
    persistence_lambda_arn         = module.draft_metadata_persistence_lambda.lambda_arn,
    draft_metadata_bucket          = local.draft_metadata_s3_bucket_name
    environment                    = local.environment
    account_id                     = data.aws_caller_identity.current.account_id
  })
  step_function_role_policy_attachments = {
    "lambda-policy" : aws_iam_policy.draft_metadata_checks_policy.arn,
    "api-invoke-policy" : aws_iam_policy.api_invoke_policy.arn
  }
}
