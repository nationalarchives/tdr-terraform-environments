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
          "Next": "PrepareVirusDetectedQueryParams"
        }
      ],
      "Default": "RunValidateMetadataLambda"
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
