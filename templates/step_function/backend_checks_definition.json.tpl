{
  "Comment": "A description of my state machine",
  "StartAt": "Get Files",
  "States": {
    "Get Files": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "Payload.$": "$",
        "FunctionName": "${file_upload_data_arn}"
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException"
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
        "FunctionName": "${api_update_v2_arn}",
        "Payload": {
          "results": [],
          "statuses.$": "$.statuses",
          "redactedResults": {
            "redactedFiles": [],
            "errors": []
          }
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
                      "FunctionName": "${yara_av_v2_arn}",
                      "Payload.$": "$"
                    },
                    "Retry": [
                      {
                        "ErrorEquals": [
                          "Lambda.ServiceException",
                          "Lambda.AWSLambdaException",
                          "Lambda.SdkClientException"
                        ],
                        "IntervalSeconds": 2,
                        "MaxAttempts": 6,
                        "BackoffRate": 2
                      }
                    ],
                    "End": true
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
                      "FunctionName": "${file_format_v2_arn}",
                      "Payload.$": "$"
                    },
                    "Retry": [
                      {
                        "ErrorEquals": [
                          "Lambda.ServiceException",
                          "Lambda.AWSLambdaException",
                          "Lambda.SdkClientException"
                        ],
                        "IntervalSeconds": 2,
                        "MaxAttempts": 6,
                        "BackoffRate": 2
                      }
                    ],
                    "End": true
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
                      "FunctionName": "${checksum_v2_arn}",
                      "Payload.$": "$"
                    },
                    "Retry": [
                      {
                        "ErrorEquals": [
                          "Lambda.ServiceException",
                          "Lambda.AWSLambdaException",
                          "Lambda.SdkClientException"
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
            ],
            "End": true,
            "ResultPath": "$.fileCheckResults",
            "ResultSelector": {
              "antivirus.$": "$.[?(@.antivirus)].antivirus",
              "fileFormat.$": "$.[?(@.fileFormat)].fileFormat",
              "checksum.$": "$.[?(@.checksum)].checksum"
            }
          }
        }
      },
      "MaxConcurrency": 40,
      "ResultSelector": {
        "results.$": "$"
      },
      "ItemsPath": "$.results",
      "Next": "Redacted files",
      "Catch": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "Next": "Notify"
        }
      ]
    },
    "Redacted files": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "Parameters": {
        "Payload.$": "$",
        "FunctionName": "${redacted_files_arn}"
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException",
            "Lambda.TooManyRequestsException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "Next": "Generate Statuses",
      "ResultPath": "$.redactedResults",
      "ResultSelector": {
        "redactedFiles.$": "$.Payload.redactedFiles",
        "errors.$": "$.Payload.errors"
      }
    },
    "Generate Statuses": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "Parameters": {
        "Payload.$": "$",
        "FunctionName": "${statuses_arn}"
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException",
            "Lambda.TooManyRequestsException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "Next": "Update API",
      "ResultPath": "$.statuses",
      "ResultSelector": {
        "statuses.$": "$.Payload.statuses"
      }
    },
    "Update API": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "Payload.$": "$",
        "FunctionName": "${api_update_v2_arn}"
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "End": true
    },
    "Notify": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "FunctionName": "${notification_arn}",
        "Payload": {
          "consignmentId.$": "$$.Execution.Input.consignmentId",
          "error.$": "$.Error",
          "cause.$": "$.Cause",
          "environment": "intg"
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
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "Next": "Fail"
    },
    "Fail": {
      "Type": "Fail"
    }
  }
}
