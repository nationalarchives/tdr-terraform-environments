[
  {
    "name": "frontend",
    "image": "${app_image}",
    "cpu": 0,
    "secrets": [
      {
        "valueFrom": "/${app_environment}/frontend/play_secret",
        "name": "PLAY_SECRET_KEY"
      },
      {
        "valueFrom": "/${app_environment}/frontend/redis/host",
        "name": "REDIS_HOST"
      },
      {
        "valueFrom": "${client_secret_path}",
        "name": "AUTH_SECRET"
      },
      {
        "valueFrom": "${read_client_secret_path}",
        "name": "READ_AUTH_SECRET"
      }
    ],
    "environment": [
      {
        "name" : "ENVIRONMENT",
        "value" : "${app_environment}"
      },
      {
        "name": "EXPORT_API_URL",
        "value": "${export_api_url}"
      },
      {
        "name": "BACKEND_CHECKS_BASE_URL",
        "value": "${backend_checks_api_url}"
      },
      {
        "name": "ALB_IP_A",
        "value": "${alb_ip_a}"
      },
      {
        "name": "ALB_IP_B",
        "value": "${alb_ip_b}"
      },
      {
        "name": "AUTH_URL",
        "value": "${auth_url}"
      },
      {
        "name": "OTEL_SERVICE_NAME",
        "value": "${otel_service_name}"
      },
      {
        "name": "BLOCK_DRAFT_METADATA_UPLOAD",
        "value": "${block_draft_metadata_upload}"
      },
      {
        "name": "DRAFT_METADATA_VALIDATOR_API_URL",
        "value": "${draft_metadata_validator_api_url}"
      },
      {
        "name": "DRAFT_METADATA_S3_BUCKET_NAME",
        "value": "${draft_metadata_s3_bucket_name}"
      },
      {
        "name": "NOTIFICATION_SNS_TOPIC_ARN",
        "value": "${notification_sns_topic_arn}"
      },
      {
        "name": "BLOCK_METADATA_REVIEW",
        "value": "${block_metadata_review}"
      },
      {
        "name": "BLOCK_SKIP_METADATA_REVIEW",
        "value": "${block_skip_metadata_review}"
      },
      {
        "name": "FILE_CHECKS_TOTAL_TIMEOUT_IN_SECONDS",
        "value": "${file_checks_total_timeout_in_seconds}"
      }
    ],
    "networkMode": "awsvpc",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/frontend-${app_environment}",
        "awslogs-region": "${aws_region}",
        "awslogs-stream-prefix": "ecs",
        "awslogs-datetime-format": "%Y-%m-%d %H:%M:%S%L"
      }
    },
    "portMappings": [
      {
      "containerPort": 9000,
      "hostPort": 9000
    }
    ]
  }
]
