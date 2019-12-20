[
  {
    "name": "keycloak",
    "image": "${app_image}",
    "cpu": 0,
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
      },
      {
        "valueFrom": "${admin_user_path}",
        "name": "KEYCLOAK_USER"
      },
      {
        "valueFrom": "${admin_password_path}",
        "name": "KEYCLOAK_PASSWORD"
      }
    ],
    "environment": [
      {
        "name" : "DB_VENDOR",
        "value" : "mysql"
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
