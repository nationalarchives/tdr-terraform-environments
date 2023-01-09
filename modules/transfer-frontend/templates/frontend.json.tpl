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
        "name": "BLOCK_FEATURE_CUSTOM_METADATA",
        "value": "${block_feature_custom_metadata}"
      },
      {
        "name": "BLOCK_FEATURE_DESCRIPTIVE_METADATA",
        "value": "${block_feature_descriptive_metadata}"
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
