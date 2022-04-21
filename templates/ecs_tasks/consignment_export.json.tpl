[
  {
    "name": "consignmentexport",
    "image": "${management_account}.dkr.ecr.${region}.amazonaws.com/consignment-export:${app_environment}",
    "networkMode": "awsvpc",
    "secrets": [
      {
        "name": "CLIENT_SECRET",
        "valueFrom": "${backend_client_secret_path}"
      }
    ],
    "environment": [
      {
        "name": "CLEAN_BUCKET",
        "value": "${clean_bucket}"
      },
      {
        "name": "OUTPUT_BUCKET",
        "value": "${output_bucket}"
      },
      {
        "name": "OUTPUT_BUCKET_JUDGMENT",
        "value": "${output_bucket_judgment}"
      },
      {
        "name": "API_URL",
        "value": "${api_url}"
      },
      {
        "name": "AUTH_URL",
        "value": "${auth_url}"
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
