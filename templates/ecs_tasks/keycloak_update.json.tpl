[
  {
    "name": "${project}-keycloak-update",
    "image": "${management_account}.dkr.ecr.eu-west-2.amazonaws.com/keycloak-update:${app_environment}",
    "cpu": 0,
    "secrets": [
      {
        "valueFrom": "${client_secret_path}",
        "name": "CLIENT_SECRET"
      },
      {
        "valueFrom": "${backend_checks_secret_path}",
        "name": "BACKEND_CHECKS_CLIENT_SECRET"
      },
      {
        "valueFrom": "${realm_admin_secret_path}",
        "name": "REALM_ADMIN_CLIENT_SECRET"
      },
      {
        "valueFrom": "${keycloak_properties_path}",
        "name": "KEYCLOAK_CONFIGURATION_PROPERTIES"
      },
      {
        "valueFrom": "${user_admin_path}",
        "name": "USER_ADMIN_CLIENT_SECRET"
      },
      {
        "valueFrom": "${reporting_secret_path}",
        "name": "REPORTING_CLIENT_SECRET"
      },
      {
        "valueFrom": "${github_secret_path}",
        "name": "GITHUB_TOKEN"
      }
    ],
    "environment": [
      {
        "name": "ENVIRONMENT",
        "value": "${app_environment}"
      },
      {
        "name": "UPDATE_POLICY",
        "value": "SKIP"
      }
    ],
    "networkMode": "awsvpc",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${log_group_name}",
        "awslogs-region": "eu-west-2",
        "awslogs-stream-prefix": "ecs"
      }
    },
    "portMappings": [
      {
        "containerPort": 3000,
        "hostPort": 3000
      }
    ]
  }
]
