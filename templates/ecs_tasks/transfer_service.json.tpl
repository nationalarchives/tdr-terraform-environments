[
  {
    "name": "transfer-service",
    "image": "${app_image}",
    "networkMode": "awsvpc",
    "secrets": [
      {
        "name": "TRANSFER_SERVICE_CLIENT_SECRET",
        "valueFrom": "${transfer_service_client_secret_path}"
      }
    ],
    "environment": [
       {
         "name": "AWS_REGION",
         "value": "${aws_region}"
       },
       {
         "name": "RECORDS_UPLOAD_BUCKET_ARN",
         "value": "${records_upload_bucket_arn}"
       },
       {
         "name": "RECORDS_UPLOAD_BUCKET_NAME",
         "value": "${records_upload_bucket_name}"
       },
       {
         "name": "METADATA_UPLOAD_BUCKET_ARN",
         "value": "${metadata_upload_bucket_arn}"
       },
       {
         "name": "METADATA_UPLOAD_BUCKET_NAME",
         "value": "${metadata_upload_bucket_name}"
       },
       {
         "name": "CONSIGNMENT_API_URL",
         "value": "${consignment_api_url}/graphql"
       },
       {
         "name": "AUTH_URL",
         "value": "${auth_url}"
       },
       {
         "name": "API_PORT",
         "value": "${transfer_service_api_port}"
       },
       {
        "name": "MAX_NUMBER_RECORDS",
        "value": "${max_number_records}"
       },
       {
         "name": "MAX_INDIVIDUAL_FILE_SIZE_MB",
         "value": "${max_individual_file_size_mb}"
       },
       {
         "name": "MAX_TRANSFER_SIZE_MB",
         "value": "${max_transfer_size_mb}"
       },
      {
        "name": "THROTTLE_AMOUNT",
        "value": "${throttle_amount}"
      },
      {
        "name": "THROTTLE_PER_MS",
        "value": "${throttle_per_ms}"
      },
      {
        "name": "USER_EMAIL_SNS_TOPIC_ARN",
        "value": "${user_email_sns_topic_arn}"
      },
      {
        "name": "USER_READ_CLIENT_ID",
        "value": "${user_read_client_id}"
      },
      {
        "name": "USER_READ_CLIENT_SECRET",
        "value": "${user_read_client_secret}"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${log_group_name}",
        "awslogs-region": "${aws_region}",
        "awslogs-stream-prefix": "ecs"
      }
    },
    "portMappings": [
      {
        "containerPort": 8080,
        "hostPort": 8080
      }
    ]
  }
]
