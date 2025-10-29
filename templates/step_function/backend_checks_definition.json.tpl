{
  "Comment": "A state machine to run all backend checks",
  "StartAt": "Get Files",
  "States": {
    "Get Files": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "Payload.$": "$",
        "FunctionName": "${file_upload_data_lambda_arn}"
      },
      "Retry": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "Next": "In Progress Status API Update"
    },
    "In Progress Status API Update": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "Parameters": {
        "FunctionName": "${api_update_v2_lambda_arn}",
        "Payload.$": "$"
      },
      "Retry": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "ResultPath": null,
      "Next": "Map"
    },
    "Map": {
      "Type": "Map",
      "Iterator": {
        "StartAt": "Run all checks",
        "States": {
          "Run all checks": {
            "Type": "Parallel",
            "Branches": [
              {
                "StartAt": "Antivirus",
                "States": {
                  "Antivirus": {
                    "Type": "Task",
                    "Resource": "arn:aws:states:::lambda:invoke",
                    "OutputPath": "$.Payload",
                    "Parameters": {
                      "FunctionName": "${yara_av_v2_lambda_arn}",
                      "Payload.$": "$"
                    },
                    "End": true,
                    "Catch": [
                      {
                        "ErrorEquals": [
                          "States.ALL"
                        ],
                        "Next": "AV Notify"
                      }
                    ]
                  },
                  "AV Notify": {
                    "Type": "Task",
                    "Resource": "arn:aws:states:::lambda:invoke",
                    "Parameters": {
                      "FunctionName": "${notification_lambda_arn}",
                      "Payload": {
                        "consignmentId.$": "$$.Execution.Input.consignmentId",
                        "error": "The antivirus lambda has failed",
                        "cause.$": "$.Cause",
                        "environment": "${environment}"
                      }
                    },
                    "End": true,
                    "ResultPath": null
                  }
                }
              },
              {
                "StartAt": "File Format",
                "States": {
                  "File Format": {
                    "Type": "Task",
                    "Resource": "arn:aws:states:::lambda:invoke",
                    "OutputPath": "$.Payload",
                    "Parameters": {
                      "FunctionName": "${file_format_v2_lambda_arn}",
                      "Payload.$": "$"
                    },
                    "Retry": [
                      {
                        "ErrorEquals": [
                          "States.ALL"
                        ],
                        "IntervalSeconds": 2,
                        "MaxAttempts": 6,
                        "BackoffRate": 2
                      }
                    ],
                    "End": true,
                    "Catch": [
                      {
                        "ErrorEquals": [
                          "States.ALL"
                        ],
                        "Next": "File Format Notify"
                      }
                    ]
                  },
                  "File Format Notify": {
                    "Type": "Task",
                    "Resource": "arn:aws:states:::lambda:invoke",
                    "Parameters": {
                      "FunctionName": "${notification_lambda_arn}",
                      "Payload": {
                        "consignmentId.$": "$$.Execution.Input.consignmentId",
                        "error": "The file format lambda has failed",
                        "cause.$": "$.Cause",
                        "environment": "${environment}"
                      }
                    },
                    "End": true,
                    "ResultPath": null
                  }
                }
              },
              {
                "StartAt": "Checksum",
                "States": {
                  "Checksum": {
                    "Type": "Task",
                    "Resource": "arn:aws:states:::lambda:invoke",
                    "OutputPath": "$.Payload",
                    "Parameters": {
                      "FunctionName": "${checksum_v2_lambda_arn}",
                      "Payload.$": "$"
                    },
                    "Retry": [
                      {
                        "ErrorEquals": [
                          "States.ALL"
                        ],
                        "IntervalSeconds": 2,
                        "MaxAttempts": 6,
                        "BackoffRate": 2
                      }
                    ],
                    "End": true,
                    "Catch": [
                      {
                        "ErrorEquals": [
                          "States.ALL"
                        ],
                        "Next": "Checksum Notify"
                      }
                    ]
                  },
                  "Checksum Notify": {
                    "Type": "Task",
                    "Resource": "arn:aws:states:::lambda:invoke",
                    "Parameters": {
                      "FunctionName": "${notification_lambda_arn}",
                      "Payload": {
                        "consignmentId.$": "$$.Execution.Input.consignmentId",
                        "error": "The checksum lambda has failed",
                        "cause.$": "$.Cause",
                        "environment": "${environment}"
                      }
                    },
                    "End": true,
                    "ResultPath": null
                  }
                }
              }
            ],
            "End": true,
            "ResultPath": "$.fileCheckResults",
            "ResultSelector": {
              "antivirus.$": "$.[?(@.antivirus)].antivirus",
              "fileFormat.$": "$.[?(@.fileFormat)].fileFormat",
              "checksum.$": "$.[?(@.checksum)].checksum"
            }
          }
        },
        "ProcessorConfig": {
          "Mode": "DISTRIBUTED",
          "ExecutionType": "STANDARD"
        }
      },
      "MaxConcurrency": 40,
      "ResultSelector": {
        "results.$": "$"
      },
      "Next": "Process Map Results",
      "Label": "Map",
      "ItemReader": {
        "Resource": "arn:aws:states:::s3:getObject",
        "ReaderConfig": {
          "InputType": "JSON"
        },
        "Parameters": {
          "Bucket.$": "$.bucket",
          "Key.$": "$.key"
        }
      },
      "ResultWriter": {
        "Resource": "arn:aws:states:::s3:putObject",
        "Parameters": {
          "Bucket.$": "$.bucket",
          "Prefix.$": "$.key"
        }
      }
    },
    "Process Map Results": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "Payload.$": "$",
        "FunctionName": "${backend_checks_results_arn}"
      },
      "Retry": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "Next": "Redacted files"
    },
    "Redacted files": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "Parameters": {
        "Payload.$": "$",
        "FunctionName": "${redacted_files_lambda_arn}"
      },
      "Retry": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "Next": "Generate Statuses",
      "ResultPath": null
    },
    "Generate Statuses": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "Parameters": {
        "Payload.$": "$",
        "FunctionName": "${statuses_lambda_arn}"
      },
      "Retry": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "Next": "Update API",
      "ResultPath": null
    },
    "Update API": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "Payload.$": "$",
        "FunctionName": "${api_update_v2_lambda_arn}"
      },
      "Retry": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "End": true
    }
  }
}
