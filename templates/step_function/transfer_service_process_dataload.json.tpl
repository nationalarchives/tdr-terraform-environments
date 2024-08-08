{
  "Comment": "Reads object keys from s3 bucket to process objects individually",
  "StartAt": "RetrieveS3ObjectKeys",
  "States": {
    "RetrieveS3ObjectKeys": {
      "Type": "Map",
      "ItemProcessor": {
        "ProcessorConfig": {
          "Mode": "DISTRIBUTED",
          "ExecutionType": "EXPRESS"
        },
        "StartAt": "Succeed",
        "States": {
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
          "Prefix.$": "$$.Execution.Input.metatadataSourcePrefix"
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
