module "draft_metadata_validator_lambda" {
  source          = "./da-terraform-modules/lambda"
  function_name   = "tdr-draft-metadata-validator-${local.environment}"
  handler         = "uk.gov.nationalarchives.draftmetadatavalidator.Lambda::handleRequest"
  runtime         = local.runtime_java_11
  tags            = local.common_tags
  timeout_seconds = 120
  memory_size     = 1024
  policies = {
    "TDRDraftMetadataValidatorLambdaPolicy${title(local.environment)}" = templatefile("./templates/iam_policy/draft_metadata_validator_lambda.json.tpl", {
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
  lambda_invoke_permissions = {
    "apigateway.amazonaws.com" = "${module.draft_metadata_api_gateway.api_execution_arn}/*/POST/draft-metadata/validate/{consignmentId+}"
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
  api_method_settings = [{
    method_path        = "*/*"
    logging_level      = "INFO",
    metrics_enabled    = false,
    data_trace_enabled = false
  }]
}

module "draft_metadata_bucket" {
  source      = "./da-terraform-modules/s3"
  bucket_name = local.draft_metadata_s3_bucket_name
  common_tags = local.common_tags
  kms_key_arn = module.s3_internal_kms_key.kms_key_arn
}

data "aws_ssm_parameter" "backend_checks_keycloak_secret" {
  name = local.keycloak_backend_checks_secret_name
}

resource "aws_events_connection" "consignment_api_connection" {
  name               = "TDRConsignmentAPIConnection${title(local.environment)}"
  authorization_type = "OAUTH_CLIENT_CREDENTIALS"

  auth_parameters {
    oauth {
      client_parameters {
        client_id     = local.keycloak_backend-checks_client_id
        client_secret = data.aws_ssm_parameter.backend_checks_keycloak_secret
      }

      authorization_endpoint = local.keycloak_auth_url
      http_method            = "POST"

      oauth_http_parameters {
        body_parameters {
          key   = "grant_type"
          value = "client_credentials"
        }
      }
    }
  }
}

module "draft_metadata_checks" {
  source = "./da-terraform-modules/sfn"
  step_function_name = "TDRMetadataChecks${title(local.environment)}"
  step_function_definition = jsonencode(
    {
      "Comment": "Run antivirus checks on metadata, update DB if positive, else trigger metadata validation",
      "StartAt": "RunAntivirusLambda",
      "States": {
        "CallCheckLambda": {
          "Type": "Task",
          "Resource": module.yara_av_v2.lambda_arn
          "Parameters": {
            "consignmentId.$": "$.consignmentId",
            "fileId.$": "draft-metadata.csv",
            "scanType.$": "metadata"
          },
          "Next": "CheckAntivirusResults"
        },
        "CheckAntivirusResults": {
          "Type": "Choice",
          "Choices": [
            {
              "Variable": "$.result",
              "StringEquals": "",
              "Next": "ValidateMetadataLambda"
            },
            {
              "Not": {
                "Variable": "$.result",
                "StringEquals": ""
              },
              "Next": "PrepareVirusDetectedQueryParams"
            }
          ],
          "Default": "CallValidateMetadataLambda"
        },
        "PrepareVirusDetectedQueryParams": {
          "Type": "Pass",
          "ResultPath": "$.statusUpdate",
          "Parameters": {
            "query.$": "States.Format('mutation { updateConsignmentStatus(consignmentId: \"{}\", statusType: \"DraftMetadata\" , statusValue: \"VirusDetected\") { consignmentId statusValue } }', $.consignmentId)"
          },
          "Next": "UpdateDraftMetadataStatus"
        },
        "UpdateDraftMetadataStatus": {
          "Type": "Task",
          "Resource": "arn:aws:states:::http:invoke",
          "Parameters": {
            "ApiEndpoint": "${module.consignment_api.api_url}/consignment",
            "Method": "POST",
            "Authentication": aws_events_connection.consignment_api_connection
            "Headers": {
              "Content-Type": "application/json"
            },
            "RequestBody.$": "$.statusUpdate.query"
          },
          "End": true
        },
        "CallValidateMetadataLambda": {
          "Type": "Task",
          "Resource": module.draft_metadata_validator_lambda,
          "Parameters": {
            "consignmentId.$": "$.consignmentId"
          },
          "End": true
        }
      }
    }
  )
  step_function_role_policy_attachments = {}
}
