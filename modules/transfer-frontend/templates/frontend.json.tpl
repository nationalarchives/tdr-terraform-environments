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
        "valueFrom": "${backend_checks_client_secret_path}",
        "name": "BACKEND_CHECKS_AUTH_SECRET"
      }
    ],
    "environment": [
      {
        "name" : "ENVIRONMENT",
        "value" : "${app_environment}"
      },
      {
        "name": "IDENTITY_POOL_ID",
        "value": "${identity_pool_id}"
      }
    ],
    "networkMode": "awsvpc",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/frontend-${app_environment}",
        "awslogs-region": "${aws_region}",
        "awslogs-stream-prefix": "ecs"
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
