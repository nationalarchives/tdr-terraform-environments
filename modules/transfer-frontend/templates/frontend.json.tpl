[
  {
    "name": "wiz-sensor",
    "image": "wizio.azurecr.io/sensor-serverless:v1",
    "repositoryCredentials": {
      "credentialsParameter": "${wiz_registry_credentials_arn}"
    },
    "cpu": 0,
    "portMappings": [],
    "essential": false,
    "environment": [],
    "environmentFiles": [],
    "mountPoints": [],
    "volumesFrom": [],
    "systemControls": []
  },
  {
    "name": "aws-otel-collector",
    "image": "${collector_image}",
    "cpu": 256,
    "memory": 512,
    "portMappings": [],
    "essential": true,
    "command": [
      "--config=/etc/ecs/custom-config.yml"
    ],
    "environment": [],
    "mountPoints": [],
    "volumesFrom": [],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/aws-otel-collector-${app_environment}",
        "awslogs-region": "${aws_region}",
        "awslogs-stream-prefix": "ecs"
      }
    }
  },
  {
    "name": "frontend",
    "image": "${app_image}",
    "cpu": 0,
    "entryPoint": [
      "/opt/wiz/sensor/wiz-sensor",
      "daemon",
      "--"
    ],
    "volumesFrom": [
      {
        "sourceContainer": "wiz-sensor",
        "readOnly": false
      }
    ],    
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
      },
      {
        name = "WIZ_API_CLIENT_ID"
        valueFrom = "${wiz_sensor_service_account_arn}:WIZ_API_CLIENT_ID::"
      },
      {
        name = "WIZ_API_CLIENT_SECRET"
        valueFrom = "${wiz_sensor_service_account_arn}:WIZ_API_CLIENT_SECRET::"
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
        "name": "FILE_CHECKS_TOTAL_TIMEOUT_IN_SECONDS",
        "value": "${file_checks_total_timeout_in_seconds}"
      },
      {
        "name": "BLOCK_SKIP_METADATA_REVIEW",
        "value": "${block_skip_metadata_review}"
      },
      {
        "name": "BLOCK_JUDGMENT_PRESS_SUMMARIES",
        "value": "${block_judgment_press_summaries}"
      }
    ],
    "dependsOn": [
      {
        "containerName": "wiz-sensor",
        "condition": "COMPLETE"
      }
    ],
    "linuxParameters": {
      "capabilities": {
        "add": ["SYS_PTRACE"]
      }
    },
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
