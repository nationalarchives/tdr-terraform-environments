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
      },
      {
        "valueFrom" : "${client_secret_path}",
        "name": "CLIENT_SECRET"
      },
      {
        "valueFrom": "${backend_checks_client_secret_path}",
        "name": "BACKEND_CHECKS_CLIENT_SECRET"
      },
      {
        "valueFrom": "${realm_admin_client_secret_path}",
        "name": "REALM_ADMIN_CLIENT_SECRET"
      }
    ],
    "environment": [
      {
        "valueFrom": "${configuration_properties_path}",
        "name" : "KEYCLOAK_CONFIGURATION_PROPERTIES"
      },
      {
        "name" : "FRONTEND_URL",
        "value" : "${frontend_url}"
      },
      {
        "name" : "DB_VENDOR",
        "value" : "mysql"
      },
      {
        "name" : "KEYCLOAK_IMPORT",
        "value": "/tmp/tdr-realm.json"
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
