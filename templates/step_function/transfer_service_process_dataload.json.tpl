{
  "Comment": "Reads metadata object keys from s3 bucket to process objects individually",
  "StartAt": "RetrieveMetadataS3ObjectKeys",
  "States": {
    "RetrieveMetadataS3ObjectKeys": {
      "Type": "Map",
      "ItemProcessor": {
        "ProcessorConfig": {
          "Mode": "DISTRIBUTED",
          "ExecutionType": "EXPRESS"
        },
        "StartAt": "FilterOutPrefixFromObjectKeys",
        "States": {
          "FilterOutPrefixFromObjectKeys": {
            "Type": "Choice",
            "Choices": [
              {
                "Variable": "$.MapItem.Key",
                "StringEqualsPath": "$.ExecutionInput.metadataSourcePrefix",
                "Next": "IgnorePrefixObjectKey"
              }
            ],
            "Default": "RunMetadataAntivirusScan"
          },
          "RunMetadataAntivirusScan": {
            "Comment": "FileId is derived from the Item Key. No upload bucket as clean metadata json files remain in dirty bucket for processing",
            "Type": "Task",
            "Resource": "arn:aws:states:::lambda:invoke",
            "Parameters": {
              "FunctionName": "${antivirus_lambda_arn}:$LATEST",
              "Payload": {
                "consignmentId.$": "$.ExecutionInput.transferId",
                "fileId.$": "States.ArrayGetItem(States.StringSplit($.MapItem.Key, '/'), States.MathAdd(States.ArrayLength(States.StringSplit($.MapItem.Key, '/')), -1))",
                "originalPath.$": "$.MapItem.Key",
                "s3SourceBucket.$": "$.ExecutionInput.metadataSourceBucket",
                "s3SourceBucketKey.$": "$.MapItem.Key",
                "s3UploadBucket": "",
                "s3UploadBucketKey": ""
              }
            },
            "Retry": [
              {
                "ErrorEquals": [
                  "Lambda.ServiceException",
                  "Lambda.AWSLambdaException",
                  "Lambda.SdkClientException",
                  "Lambda.TooManyRequestsException"
                ],
                "IntervalSeconds": 1,
                "MaxAttempts": 3,
                "BackoffRate": 2
              }
            ],
            "Next": "CheckMetadataAntivirusResults",
            "ResultPath": "$.AntivirusOutput"
          },
          "CheckMetadataAntivirusResults": {
            "Type": "Choice",
            "Choices": [
              {
                "Not": {
                  "Variable": "$.AntivirusOutput.Payload.antivirus.result",
                  "StringEquals": ""
                },
                "Next": "TagMetadataAntivirusCompletedWithIssues"
              }
            ],
            "Default": "Succeed"
          },
          "TagMetadataAntivirusCompletedWithIssues": {
            "Type": "Task",
            "Parameters": {
              "Bucket.$": "$.ExecutionInput.metadataSourceBucket",
              "Key.$": "$.MapItem.Key",
              "Tagging": {
                "TagSet": [
                  {
                    "Key": "Antivirus",
                    "Value": "CompletedWithIssues"
                  }
                ]
              }
            },
            "Resource": "arn:aws:states:::aws-sdk:s3:putObjectTagging",
            "Next": "VirusDetected"
          },
          "IgnorePrefixObjectKey": {
           "Type": "Succeed",
           "Comment": "Map Keys include the prefix which is not a digital object so cannot be processed"
          },
          "VirusDetected": {
            "Type": "Succeed",
            "Comment": "Stop processing as virus detected in metadata json"
          },
          "Succeed": {
            "Type": "Succeed",
            "Comment": "Temporary state for skeleton step function"
          }
        }
      },
      "ItemReader": {
        "Resource": "arn:aws:states:::s3:listObjectsV2",
        "Parameters": {
          "Bucket.$": "$$.Execution.Input.metadataSourceBucket",
          "Prefix.$": "$$.Execution.Input.metadataSourcePrefix"
        }
      },
      "MaxConcurrency": 100,
      "Label": "S3ObjectKeys",
      "End": true,
      "ItemSelector": {
        "MapItem.$": "$$.Map.Item.Value",
        "ExecutionInput.$": "$$.Execution.Input"
      }
    }
  }
}
