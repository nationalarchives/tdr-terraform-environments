{
  "Comment": "Run antivirus checks on metadata, write error file to s3 and update status if virus found, else trigger metadata validation",
  "StartAt": "SplitDate",
  "States": {
    "SplitDate": {
      "Type": "Pass",
      "ResultPath": "$.splitDate",
      "Parameters": {
        "YYYY.$": "States.ArrayGetItem(States.StringSplit(States.ArrayGetItem(States.StringSplit($$.Execution.StartTime, 'T'), 0), '-'), 0)",
        "MM.$": "States.ArrayGetItem(States.StringSplit(States.ArrayGetItem(States.StringSplit($$.Execution.StartTime, 'T'),0), '-'), 1)",
        "DD.$": "States.ArrayGetItem(States.StringSplit(States.ArrayGetItem(States.StringSplit($$.Execution.StartTime, 'T'),0), '-'), 2)"
      },
      "Next": "RunAntivirusLambda"
    },
    "RunAntivirusLambda": {
      "Type": "Task",
      "Resource": "${antivirus_lambda_arn}",
      "Parameters": {
        "consignmentId.$": "$.consignmentId",
        "fileId.$": "$.fileName",
        "scanType": "metadata"
      },
      "ResultPath": "$.output",
      "Next": "CheckAntivirusResults"
    },
    "CheckAntivirusResults": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.output.antivirus.result",
          "StringEquals": "",
          "Next": "RunMetadataChecksLambda"
        }
      ],
      "Default": "SendSNSVirusMessage"
    },
    "SendSNSVirusMessage": {
      "Type": "Task",
      "Resource": "arn:aws:states:::sns:publish",
      "Parameters": {
        "TopicArn": "arn:aws:sns:eu-west-2:${account_id}:tdr-notifications-${environment}",
        "Message": {
          "consignmentId.$": "$.consignmentId",
          "environment": "${environment}",
          "metaDataError": "Virus found in metadata file",
          "cause.$": "$.output.antivirus.result"
        }
      },
      "Next": "WriteVirusDetectedJsonToS3",
      "ResultPath": null
    },
    "WriteVirusDetectedJsonToS3": {
      "Type": "Task",
      "Resource": "arn:aws:states:::aws-sdk:s3:putObject",
      "ResultPath": "$.s3PutObjectResult",
      "Parameters": {
        "Bucket": "${draft_metadata_bucket}",
        "Key.$": "States.Format('{}/draft-metadata-errors.json', $.consignmentId)",
        "Body": {
          "consignmentId.$": "$.consignmentId",
          "date.$": "States.Format('{}-{}-{}',$.splitDate.YYYY,$.splitDate.MM, $.splitDate.DD)",
          "fileError": "VIRUS",
          "validationErrors": [
            {
              "assetId.$": "$.fileName",
              "errors": [
                {
                  "validationProcess": "FILE_CHECK",
                  "property": "virus_check",
                  "errorKey": "virus",
                  "message.$": "$.output.antivirus.result"
                }
              ],
              "data": []
            }
          ]
        },
        "ContentType": "application/json"
      },
      "Next": "PrepareStatusCompletedWithIssuesParameters"
    },
    "PrepareStatusCompletedWithIssuesParameters": {
      "Type": "Pass",
      "ResultPath": "$.statusUpdate",
      "Parameters": {
        "query": "mutation updateConsignmentStatus($updateConsignmentStatusInput: ConsignmentStatusInput!) { updateConsignmentStatus(updateConsignmentStatusInput: $updateConsignmentStatusInput) }",
        "variables": {
          "updateConsignmentStatusInput": {
            "consignmentId.$": "$.consignmentId",
            "statusType": "DraftMetadata",
            "statusValue": "CompletedWithIssues"
          }
        }
      },
      "Next": "UpdateDraftMetadataStatus"
    },
    "PrepareStatusCompletedParameters": {
          "Type": "Pass",
          "ResultPath": "$.statusUpdate",
          "Parameters": {
            "query": "mutation updateConsignmentStatus($updateConsignmentStatusInput: ConsignmentStatusInput!) { updateConsignmentStatus(updateConsignmentStatusInput: $updateConsignmentStatusInput) }",
            "variables": {
              "updateConsignmentStatusInput": {
                "consignmentId.$": "$.consignmentId",
                "statusType": "DraftMetadata",
                "statusValue": "Completed"
              }
            }
          },
          "Next": "UpdateDraftMetadataStatus"
    },
    "UpdateDraftMetadataStatus": {
      "Type": "Task",
      "Resource": "arn:aws:states:::http:invoke",
      "Parameters": {
        "ApiEndpoint": "${consignment_api_url}/graphql",
        "Method": "POST",
        "Authentication": {
          "ConnectionArn": "${consignment_api_connection_arn}"
        },
        "Headers": {
          "Content-Type": "application/json"
        },
        "RequestBody.$": "$.statusUpdate"
      },
      "End": true
    },
    "RunMetadataChecksLambda": {
      "Type": "Task",
      "Resource": "${checks_lambda_arn}",
      "Parameters": {
        "consignmentId.$": "$.consignmentId"
      },
      "ResultPath": "$.checksLambdaResult",
      "Catch": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "ResultPath": "$.error",
          "Next": "SendSNSErrorMessage"
        }
      ],
      "Next": "CheckMetadataValidationStatus"
    },
    "CheckMetadataValidationStatus": {
      "Type": "Choice",
      "Choices": [
        {
          "Not": {
            "Variable": "$.checksLambdaResult.validationStatus",
            "IsPresent": true
          },
          "Next": "SendSNSErrorMessage"
        },
        {
          "Variable": "$.checksLambdaResult.validationStatus",
          "StringEquals": "success",
          "Next": "RunPersistenceMetadataLambda"
        },
        {
          "Variable": "$.checksLambdaResult.validationStatus",
          "StringEquals": "failure",
          "Next": "PrepareStatusCompletedWithIssuesParameters"
        }
      ],
      "Default": "SendSNSErrorMessage"
    },
    "RunPersistenceMetadataLambda": {
      "Type": "Task",
      "Resource": "${persistence_lambda_arn}",
      "Parameters": {
        "consignmentId.$": "$.consignmentId"
      },
      "ResultPath": "$.checksLambdaResult",
      "Catch": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "ResultPath": "$.error",
          "Next": "SendSNSErrorMessage"
        }
      ],
      "Next": "CheckMetadataPersistenceStatus"
    },
    "CheckMetadataPersistenceStatus": {
      "Type": "Choice",
      "Choices": [
        {
          "Not": {
            "Variable": "$.checksLambdaResult.persistenceStatus",
            "IsPresent": true
          },
          "Next": "SendSNSErrorMessage"
        },
        {
          "Variable": "$.checksLambdaResult.persistenceStatus",
          "StringEquals": "failure",
          "Next": "PrepareStatusCompletedWithIssuesParameters"
        },
        {
          "Variable": "$.checksLambdaResult.persistenceStatus",
          "StringEquals": "success",
          "Next": "PrepareStatusCompletedParameters"
        }
      ],
      "Default": "SendSNSErrorMessage"
    },
    "SendSNSErrorMessage": {
      "Type": "Task",
      "Resource": "arn:aws:states:::sns:publish",
      "Parameters": {
        "TopicArn": "arn:aws:sns:eu-west-2:${account_id}:tdr-notifications-${environment}",
        "Message": {
          "consignmentId.$": "$.consignmentId",
          "environment": "${environment}",
          "metaDataError": "An unknown error has been triggered",
          "cause.$": "States.Format('Metadata validation lambda: {}',$.error.Cause)"
        }
      },
      "Next": "WriteUnknownErrorJsonToS3",
      "ResultPath": null
    },
    "WriteUnknownErrorJsonToS3": {
      "Type": "Task",
      "Resource": "arn:aws:states:::aws-sdk:s3:putObject",
      "ResultPath": "$.s3PutObjectResult",
      "Parameters": {
        "Bucket": "${draft_metadata_bucket}",
        "Key.$": "States.Format('{}/draft-metadata-errors.json', $.consignmentId)",
        "Body": {
          "consignmentId.$": "$.consignmentId",
          "date.$": "States.Format('{}-{}-{}',$.splitDate.YYYY,$.splitDate.MM, $.splitDate.DD)",
          "fileError": "UNKNOWN",
          "validationErrors": [
            {
              "assetId.$": "$.fileName",
              "errors": [
                {
                  "validationProcess": "LAMBDA",
                  "property": "lambda_validation",
                  "errorKey": "unexpected_error",
                  "message.$": "$.error.Cause"
                }
              ],
              "data": []
            }
          ]
        },
        "ContentType": "application/json"
      },
      "Next": "PrepareStatusCompletedWithIssuesParameters"
    }
  }
}
