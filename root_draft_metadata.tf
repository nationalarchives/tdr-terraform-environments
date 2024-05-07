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
  name = "TDRMetadataChecksAPIGatewayExecutionRole${title(local.environment)}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "apigateway.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  inline_policy {
    name = "TDRMetadataChecksAPIGatewayStepFunctionExecutionPolicy${title(local.environment)}"
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Action = "states:StartExecution",
          Resource = module.draft_metadata_checks.step_function_arn
        }
      ]
    })
  }
}

module "draft_metadata_bucket" {
  source      = "./da-terraform-modules/s3"
  bucket_name = local.draft_metadata_s3_bucket_name
  common_tags = local.common_tags
  kms_key_arn = module.s3_internal_kms_key.kms_key_arn
}

data "aws_ssm_parameter" "backend_checks_keycloak_secret" {
  name            = local.keycloak_backend_checks_secret_name
  with_decryption = true
}

resource "aws_cloudwatch_event_connection" "consignment_api_connection" {
  name               = "TDRConsignmentAPIConnection${title(local.environment)}"
  authorization_type = "OAUTH_CLIENT_CREDENTIALS"

  auth_parameters {
    oauth {
      client_parameters {
        client_id     = local.keycloak_backend-checks_client_id
        client_secret = data.aws_ssm_parameter.backend_checks_keycloak_secret.value
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
  description = "Policy to allow necessary lambda executions from step function"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = [
          module.yara_av_v2.lambda_arn,
          module.draft_metadata_validator_lambda.lambda_arn
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "api_invoke_policy" {
    name = "TDRAPIInvokePolicy${title(local.environment)}"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid       = "Statement1"
          Effect    = "Allow"
          Action    = "states:InvokeHTTPEndpoint"
          Resource  = module.draft_metadata_checks.step_function_arn
          Condition = {
            StringEquals = {
              "states:HTTPMethod" = "POST"
            }
            StringLike = {
              "states:HTTPEndpoint" = "${module.consignment_api.api_url}/*"
            }
          }
        },
        {
          Sid     = "Statement2"
          Effect  = "Allow"
          Action  = "events:RetrieveConnectionCredentials"
          Resource = aws_cloudwatch_event_connection.consignment_api_connection.arn
        },
        {
          Sid     = "Statement3"
          Effect  = "Allow"
          Action  = [
            "secretsmanager:GetSecretValue",
            "secretsmanager:DescribeSecret"
          ]
          Resource = "arn:aws:secretsmanager:*:*:secret:events!connection/*"
        }
      ]
    })
  }

module "draft_metadata_checks" {
  source             = "./da-terraform-modules/sfn"
  step_function_name = "TDRMetadataChecks${title(local.environment)}"
  step_function_definition = jsonencode(
    {
      "Comment" : "Run antivirus checks on metadata, update DB if positive, else trigger metadata validation",
      "StartAt" : "RunAntivirusLambda",
      "States" : {
        "RunAntivirusLambda" : {
          "Type" : "Task",
          "Resource" : module.yara_av_v2.lambda_arn
          "Parameters" : {
            "consignmentId.$" : "$.consignmentId",
            "fileId" : "draft-metadata.csv",
            "scanType" : "metadata"
          },
          "ResultPath" : "$.output",
          "Next" : "CheckAntivirusResults"
        },
        "CheckAntivirusResults" : {
          "Type" : "Choice",
          "Choices" : [
            {
              "Variable" : "$.output.antivirus.result",
              "StringEquals" : "",
              "Next" : "RunValidateMetadataLambda"
            },
            {
              "Not" : {
                "Variable" : "$.output.antivirus.result",
                "StringEquals" : ""
              },
              "Next" : "PrepareVirusDetectedQueryParams"
            }
          ],
          "Default" : "RunValidateMetadataLambda"
        },
        "PrepareVirusDetectedQueryParams": {
          "Type" : "Pass",
          "ResultPath" : "$.statusUpdate",
          "Parameters" : {
            "query": "mutation updateConsignmentStatus($updateConsignmentStatusInput: ConsignmentStatusInput!) { updateConsignmentStatus(updateConsignmentStatusInput: $updateConsignmentStatusInput) }",
            "variables": {
              "updateConsignmentStatusInput": {
                "consignmentId.$": "$.consignmentId",
                "statusType": "DraftMetadata",
                "statusValue": "Failed"
              }
            }
          },
          "Next" : "UpdateDraftMetadataStatus"
        },
        "UpdateDraftMetadataStatus" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::http:invoke",
          "Parameters" : {
            "ApiEndpoint" : "${module.consignment_api.api_url}/graphql",
            "Method" : "POST",
            "Authentication" : {
              "ConnectionArn" : aws_cloudwatch_event_connection.consignment_api_connection.arn
            },
            "Headers" : {
              "Content-Type" : "application/json"
            },
            "RequestBody.$" : "$.statusUpdate"
          },
          "End" : true
        },
        "RunValidateMetadataLambda" : {
          "Type" : "Task",
          "Resource" : module.draft_metadata_validator_lambda.lambda_arn,
          "Parameters" : {
            "consignmentId.$" : "$.consignmentId"
          },
          "End" : true
        }
      }
    }
  )
  step_function_role_policy_attachments = {
    "lambda-policy" : aws_iam_policy.draft_metadata_checks_policy.arn,
    "api-invoke-policy": aws_iam_policy.api_invoke_policy.arn
  }
}
