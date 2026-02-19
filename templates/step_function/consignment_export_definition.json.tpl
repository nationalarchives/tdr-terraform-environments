{
  "Comment": "A state machine to run two Fargate tasks. One to create a bagit export and one to create a flattened export",
  "StartAt": "Rerun Parameters Present",
  "States": {
    "Rerun Parameters Present": {
      "Type": "Choice",
      "Choices": [
        {
          "Next": "Add Default Rerun Parameters",
          "Or": [
            {
              "Variable": "$.rerunBagit",
              "IsPresent": false
            },
            {
              "Variable": "$.rerunExport",
              "IsPresent": false
            }
          ]
        }
      ],
      "Default": "Parallel"
    },
    "Add Default Rerun Parameters": {
      "Type": "Choice",
      "Choices": [
        {
          "Next": "Add Rerun Export Default",
          "Variable": "$.rerunBagit",
          "IsPresent": true
        },
        {
          "Next": "Add Rerun Bagit Default",
          "Variable": "$.rerunExport",
          "IsPresent": true
        },
        {
          "Next": "Add Both Rerun Defaults",
          "And": [
            {
              "Variable": "$.rerunBagit",
              "IsPresent": false
            },
            {
              "Variable": "$.rerunExport",
              "IsPresent": false
            }
          ]
        }
      ]
    },
    "Add Rerun Export Default": {
      "Type": "Pass",
      "Next": "Parallel",
      "Parameters": {
        "rerunExport": "false",
        "rerunBagit.$": "$.rerunBagit",
        "consignmentId.$": "$.consignmentId"
      }
    },
    "Add Rerun Bagit Default": {
      "Type": "Pass",
      "Next": "Parallel",
      "Parameters": {
        "rerunBagit": "false",
        "rerunExport.$": "$.rerunExport",
        "consignmentId.$": "$.consignmentId"
      }
    },
    "Add Both Rerun Defaults": {
      "Type": "Pass",
      "Next": "Parallel",
      "Parameters": {
        "rerunBagit": "false",
        "rerunExport": "false",
        "consignmentId.$": "$.consignmentId"
      }
    },
    "Parallel": {
      "Type": "Parallel",
      "Next": "Task complete notification",
      "Branches": [
        {
          "StartAt": "Run ECS export",
          "States": {
            "Run ECS export": {
              "Type": "Task",
              "Resource": "arn:aws:states:::ecs:runTask.waitForTaskToken",
              "HeartbeatSeconds": 60,
              "TimeoutSeconds": 1800,
              "Retry": [
                {
                  "ErrorEquals": [
                    "States.HeartbeatTimeout",
                    "States.Timeout",
                    "ECS.AmazonECSException"
                  ],
                  "MaxAttempts": ${max_attempts}
                }
              ],
              "Parameters": {
                "LaunchType": "FARGATE",
                "Cluster": "${cluster_arn}",
                "TaskDefinition": "${task_arn}",
                "PlatformVersion": "${platform_version}",
                "NetworkConfiguration": {
                  "AwsvpcConfiguration": {
                    "AssignPublicIp": "DISABLED",
                    "SecurityGroups": ${security_groups},
                    "Subnets": ${subnet_ids}
                  }
                },
                "Overrides": {
                  "ContainerOverrides": [
                    {
                      "Name": "consignmentexport",
                      "Environment": [
                        {
                          "Name": "RERUN_EXPORT",
                          "Value.$": "$.rerunExport"
                        },
                        {
                          "Name": "RERUN_BAGIT",
                          "Value.$": "$.rerunBagit"
                        },
                        {
                          "Name": "CONSIGNMENT_ID",
                          "Value.$": "$.consignmentId"
                        },
                        {
                          "Name": "COMMAND",
                          "Value": "tdr-export"
                        },
                        {
                          "Name": "OUTPUT_BUCKET",
                          "Value": "${export_output_bucket}"
                        },
                        {
                          "Name": "OUTPUT_BUCKET_JUDGMENT",
                          "Value": "${export_output_judgment_bucket}"
                        },
                        {
                          "Name": "TASK_TOKEN_ENV_VARIABLE",
                          "Value.$": "$$.Task.Token"
                        }
                      ]
                    }
                  ]
                }
              },
              "End": true
            }
          }
        },
        {
          "StartAt": "Run ECS task Bagit",
          "States": {
            "Run ECS task Bagit": {
              "Type": "Task",
              "Resource": "arn:aws:states:::ecs:runTask.waitForTaskToken",
              "HeartbeatSeconds": 60,
              "TimeoutSeconds": 1800,
              "Retry": [
                {
                  "ErrorEquals": [
                    "States.HeartbeatTimeout",
                    "States.Timeout",
                    "ECS.AmazonECSException"
                  ],
                  "MaxAttempts": ${max_attempts}
              }
              ],
              "Parameters": {
                "LaunchType": "FARGATE",
                "Cluster": "${cluster_arn}",
                "TaskDefinition": "${task_arn}",
                "PlatformVersion": "${platform_version}",
                "NetworkConfiguration": {
                  "AwsvpcConfiguration": {
                    "AssignPublicIp": "DISABLED",
                    "SecurityGroups": ${security_groups},
                    "Subnets": ${subnet_ids}
                  }
                },
                "Overrides": {
                  "ContainerOverrides": [
                    {
                      "Name": "consignmentexport",
                      "Environment": [
                        {
                          "Name": "RERUN_EXPORT",
                          "Value.$": "$.rerunExport"
                        },
                        {
                          "Name": "RERUN_BAGIT",
                          "Value.$": "$.rerunBagit"
                        },
                        {
                          "Name": "CONSIGNMENT_ID",
                          "Value.$": "$.consignmentId"
                        },
                        {
                          "Name": "COMMAND",
                          "Value": "tdr-consignment-export"
                        },
                        {
                          "Name": "OUTPUT_BUCKET",
                          "Value": "${bagit_export_bucket}"
                        },
                        {
                          "Name": "OUTPUT_BUCKET_JUDGMENT",
                          "Value": "${bagit_export_judgment_bucket}"
                        },
                        {
                          "Name": "TASK_TOKEN_ENV_VARIABLE",
                          "Value.$": "$$.Task.Token"
                        }
                      ]
                    }
                  ]
                }
              },
              "End": true
            }
          }
        }
      ],
      "Catch": [
        {
          "ErrorEquals": [
            "States.HeartbeatTimeout",
            "States.TaskFailed",
            "States.Timeout"
          ],
          "Next": "Task failed choice"
        }
      ],
      "OutputPath": "$.[1]"
    },
    "Task complete notification": {
      "Type": "Task",
      "Resource": "arn:aws:states:::sns:publish",
      "Parameters": {
        "Message": {
          "consignmentId.$": "$$.Execution.Input.consignmentId",
          "success": true,
          "environment": "${environment}",
          "successDetails.$": "$"
        },
        "TopicArn": "${sns_topic}"
      },
      "End": true
    },
    "Task failed choice": {
      "Type": "Choice",
      "Choices": [
        {
          "Not": {
            "Variable": "$.Error",
            "StringEquals": "States.Timeout"
          },
          "Next": "Task failed notification"
        },
        {
          "Variable": "$.Error",
          "StringEquals": "States.Timeout",
          "Next": "Task timed out notification"
        }
      ]
    },
    "Task failed notification": {
      "Type": "Task",
      "Resource": "arn:aws:states:::sns:publish",
      "Parameters": {
        "Message": {
          "consignmentId.$": "$$.Execution.Input.consignmentId",
          "success": false,
          "environment": "${environment}",
          "failureCause.$": "$.Cause"
        },
        "TopicArn": "${sns_topic}"
    },
      "Next": "Export Status Update"
    },
    "Task timed out notification": {
      "Type": "Task",
      "Resource": "arn:aws:states:::sns:publish",
      "Parameters": {
        "Message": {
          "consignmentId.$": "$$.Execution.Input.consignmentId",
          "success": false,
          "environment": "${environment}",
          "failureCause": "The export task has timed out"
        },
        "TopicArn": "${sns_topic}"
      },
      "Next": "Export Status Update"
    },
    "Export Status Update": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:eu-west-2:${account_id}:function:tdr-export-status-update-${environment}",
      "Parameters": {
        "consignmentId.$": "$$.Execution.Input.consignmentId"
      },
      "Next": "Fail State"
    },
    "Fail State": {
      "Type": "Fail"
    }
  }
}
