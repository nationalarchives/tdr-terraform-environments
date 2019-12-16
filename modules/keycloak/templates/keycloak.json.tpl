[
  {
    "name": "keycloak",
    "image": "${app_image}",
    "cpu": 0,
    "secrets": [
      {
        "valueFrom": "${url_path}",
        "name": "DB_URL"
      },
      {
        "valueFrom": "${username_path}",
        "name": "DB_USERNAME"
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
        "awslogs-group": "/ecs/keycloak-${app_environment}",
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
