[
  {
    "name": "consignmentexport",
    "image": "${management_account}.dkr.ecr.${region}.amazonaws.com/consignment-export:${app_environment}",
    "networkMode": "awsvpc",
    "secrets": [
      {
        "name": "CLIENT_SECRET",
        "valueFrom": "${backend_client_secret_path}"
      },
      {
        "name": "DB_HOST",
        "valueFrom": "/${app_environment}/consignmentapi/instance/url"
      }
    ],
    "environment": [
      {
        "name": "CLEAN_BUCKET",
        "value": "${clean_bucket}"
      },
      {
        "name": "API_URL",
        "value": "${api_url}"
      },
      {
        "name": "USE_IAM_AUTH",
        "value": "true"
      },
      {
        "name": "DB_USER",
        "value": "consignment_api_user"
      },
      {
        "name": "AUTH_URL",
        "value": "${auth_url}"
      },
      {
        "name": "OUTPUT_TOPIC_ARN",
        "value": "${output_topic_arn}"
      },
      {
        "name": "DOWNLOAD_FILES_BATCH_SIZE",
        "value": "${download_files_batch_size}"
      },
      {
        "name": "DOWNLOAD_BATCH_DELAY_MS",
        "value": "${download_batch_delay_ms}"
      }
    ],
    "mountPoints": [
      {
        "containerPath": "/home/consignment-export/export",
        "sourceVolume": "consignmentexport"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${log_group_name}",
        "awslogs-region": "${region}",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]
