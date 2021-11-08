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
      },
      {
        "valueFrom": "${configuration_properties_path}",
        "name": "KEYCLOAK_CONFIGURATION_PROPERTIES"
      },
      {
        "valueFrom": "${user_admin_client_secret_path}",
        "name": "USER_ADMIN_CLIENT_SECRET"
      },
      {
        "valueFrom": "${govuk_notify_api_key_path}",
        "name": "GOVUK_NOTIFY_API_KEY"
      },
      {
        "valueFrom": "${govuk_notify_template_id_path}",
        "name": "GOVUK_NOTIFY_TEMPLATE_ID"
      },
      {
        "valueFrom": "${reporting_client_secret_path}",
        "name": "REPORTING_CLIENT_SECRET"
      }
    ],
    "environment": [
      {
        "name": "PROXY_ADDRESS_FORWARDING",
        "value": "true"
      },
      {
        "name" : "FRONTEND_URL",
        "value" : "${frontend_url}"
      },
      {
        "name" : "DB_VENDOR",
        "value" : "postgres"
      },
      {
        "name" : "KEYCLOAK_IMPORT",
        "value": "/tmp/tdr-realm.json"
      },
      {
        "name": "DB_USER",
        "value": "${username}"
      },
      {
        "name": "SNS_TOPIC_ARN",
        "value": "${sns_topic_arn}"
      },
      {
        "name": "TDR_ENV",
        "value": "${app_environment}"
      }
    ],
    "networkMode": "awsvpc",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/keycloak-auth-${app_environment}",
        "awslogs-region": "${aws_region}",
        "awslogs-stream-prefix": "ecs",
        "awslogs-datetime-format": "%Y-%m-%d %H:%M:%S%L"
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
