{
  "Comment": "A state machine to run the Fargate task to export the consignment",
  "StartAt": "Parallel",
  "States": {
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
                    "States.Timeout"
                  ],
                  "MaxAttempts": 3
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
                    "States.Timeout"
                  ],
                  "MaxAttempts": 3
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