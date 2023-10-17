[
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
        "name": "BLOCK_VALIDATION_LIBRARY",
        "value": "${block_validation_library}"
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
