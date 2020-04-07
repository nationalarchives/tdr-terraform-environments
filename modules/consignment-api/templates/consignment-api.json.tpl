[
  {
    "name": "consignmentapi",
    "image": "${app_image}",
    "cpu": 0,
    "environment": [
      {
        "name" : "AUTH_URL",
        "value" : "${auth_url}"
      },
      {
        "name" : "FRONTEND_URL",
        "value" : "${frontend_url}"
      },
      {
        "name" : "DB_PORT",
        "value" : "5432"
      }
    ],
    "secrets": [
      {
        "valueFrom": "${url_path}",
        "name": "DB_ADDR"
      },
      {
        "valueFrom": "${username_path}",
        "name": "DB_USER"
      },
      {
        "valueFrom": "${password_path}",
        "name": "DB_PASSWORD"
      }
    ],
    "networkMode": "awsvpc",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/consignment-api-${app_environment}",
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
