{
  "Comment": "Run antivirus checks on metadata, update database if positive, else trigger metadata validation",
  "StartAt": "RunAntivirusLambda",
  "States": {
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
          "Next": "RunValidateMetadataLambda"
        },
        {
          "Not": {
            "Variable": "$.output.antivirus.result",
            "StringEquals": ""
          },
          "Next": "SplitDate"
        }
      ],
      "Default": "RunValidateMetadataLambda"
    },
    "SplitDate": {
      "Type": "Pass",
      "ResultPath": "$.splitDate",
      "Parameters": {
        "YYYY.$": "States.ArrayGetItem(States.StringSplit(States.ArrayGetItem(States.StringSplit($$.Execution.StartTime, 'T'), 0), '-'), 0)",
        "MM.$": "States.ArrayGetItem(States.StringSplit(States.ArrayGetItem(States.StringSplit($$.Execution.StartTime, 'T'),0), '-'), 1)",
        "DD.$": "States.ArrayGetItem(States.StringSplit(States.ArrayGetItem(States.StringSplit($$.Execution.StartTime, 'T'),0), '-'), 2)"
      },
      "Next": "WriteVirusDetectedJsonToS3"
    },
    "WriteVirusDetectedJsonToS3": {
      "Type": "Task",
      "Resource": "arn:aws:states:::aws-sdk:s3:putObject",
      "ResultPath": "$.s3PutObjectResult",
      "Parameters": {
        "Bucket": "${draft_metadata_bucket}",
        "Key": "draft-metadata-errors.json",
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
              ]
            }
          ]
        },
        "ContentType": "application/json"
      },
      "Next": "PrepareVirusDetectedQueryParams"
    },
    "PrepareVirusDetectedQueryParams": {
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
    "RunValidateMetadataLambda": {
      "Type": "Task",
      "Resource": "${validator_lambda_arn}",
      "Parameters": {
        "consignmentId.$": "$.consignmentId"
      },
      "End": true
    }
  }
}
