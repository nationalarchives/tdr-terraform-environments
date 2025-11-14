locals {
  base_containers = [
    {
      name         = "aws-otel-collector"
      image        = "${data.aws_ssm_parameter.mgmt_account_number.value}.dkr.ecr.eu-west-2.amazonaws.com/aws-otel-collector:${var.environment}"
      cpu          = 256
      memory       = 512
      portMappings = []
      essential    = true
      command      = ["--config=/etc/ecs/custom-config.yml"]
      environment  = []
      mountPoints  = []
      volumesFrom  = []
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/aws-otel-collector-${var.environment}"
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ]

  wiz_containers = var.enable_wiz_sensor ? [
    {
      name  = "wiz-sensor"
      image = "wizio.azurecr.io/sensor-serverless:v1"
      repositoryCredentials = {
        credentialsParameter = aws_secretsmanager_secret.wiz_registry_credentials.arn
      }
      cpu              = 0
      portMappings     = []
      essential        = false
      environment      = []
      environmentFiles = []
      mountPoints = [
        {
          sourceVolume  = "sensor-host-store"
          containerPath = "/host-store"
          readOnly      = false
        }
      ]
      volumesFrom    = []
      systemControls = []
    }
  ] : []

  frontend_container = {
    name  = "frontend"
    image = "${data.aws_ssm_parameter.mgmt_account_number.value}.dkr.ecr.eu-west-2.amazonaws.com/transfer-frontend:${var.environment}"
    cpu   = 0
    entryPoint = var.enable_wiz_sensor ? [
      "/opt/wiz/sensor/wiz-sensor",
      "daemon",
      "--",
      "/bin/sh",
      "-c",
      "tdr-transfer-frontend-*/bin/tdr-transfer-frontend -Dplay.http.secret.key=$PLAY_SECRET_KEY -Dconfig.resource=application.$ENVIRONMENT.conf -Dplay.cache.redis.host=$REDIS_HOST -Dauth.secret=$AUTH_SECRET"
    ] : []

    volumesFrom = var.enable_wiz_sensor ? [
      {
        sourceContainer = "wiz-sensor"
        readOnly        = false
      }
    ] : []

    secrets = concat([
      {
        valueFrom = "/${var.environment}/frontend/play_secret"
        name      = "PLAY_SECRET_KEY"
      },
      {
        valueFrom = "/${var.environment}/frontend/redis/host"
        name      = "REDIS_HOST"
      },
      {
        valueFrom = var.client_secret_path
        name      = "AUTH_SECRET"
      },
      {
        valueFrom = var.read_client_secret_path
        name      = "READ_AUTH_SECRET"
      }
      ], var.enable_wiz_sensor ? [
      {
        name      = "WIZ_API_CLIENT_ID"
        valueFrom = "${aws_secretsmanager_secret.wiz_sensor_service_account.arn}:WIZ_API_CLIENT_ID::"
      },
      {
        name      = "WIZ_API_CLIENT_SECRET"
        valueFrom = "${aws_secretsmanager_secret.wiz_sensor_service_account.arn}:WIZ_API_CLIENT_SECRET::"
      }
    ] : [])

    environment = [
      {
        name  = "ENVIRONMENT"
        value = var.environment
      },
      {
        name  = "EXPORT_API_URL"
        value = var.export_api_url
      },
      {
        name  = "BACKEND_CHECKS_BASE_URL"
        value = var.backend_checks_api_url
      },
      {
        name  = "ALB_IP_A"
        value = var.public_subnet_ranges[0]
      },
      {
        name  = "ALB_IP_B"
        value = var.public_subnet_ranges[1]
      },
      {
        name  = "AUTH_URL"
        value = var.auth_url
      },
      {
        name  = "OTEL_SERVICE_NAME"
        value = var.otel_service_name
      },
      {
        name  = "DRAFT_METADATA_VALIDATOR_API_URL"
        value = var.draft_metadata_validator_api_url
      },
      {
        name  = "DRAFT_METADATA_S3_BUCKET_NAME"
        value = var.draft_metadata_s3_bucket_name
      },
      {
        name  = "NOTIFICATION_SNS_TOPIC_ARN"
        value = var.notification_sns_topic_arn
      },
      {
        name  = "FILE_CHECKS_TOTAL_TIMEOUT_IN_SECONDS"
        value = "480"
      },
      {
        name  = "BLOCK_SKIP_METADATA_REVIEW"
        value = tostring(var.block_skip_metadata_review)
      },
      {
        name  = "BLOCK_JUDGMENT_PRESS_SUMMARIES"
        value = tostring(var.block_judgment_press_summaries)
      }
    ]

    mountPoints = var.enable_wiz_sensor ? [
      {
        sourceVolume  = "sensor-host-store"
        containerPath = "/host-store"
        readOnly      = false
      }
    ] : []

    dependsOn = var.enable_wiz_sensor ? [
      {
        containerName = "wiz-sensor"
        condition     = "COMPLETE"
      }
    ] : []

    linuxParameters = var.enable_wiz_sensor ? {
      capabilities = {
        add = ["SYS_PTRACE"]
      }
    } : {}

    networkMode = "awsvpc"
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"           = "/ecs/frontend-${var.environment}"
        "awslogs-region"          = var.region
        "awslogs-stream-prefix"   = "ecs"
        "awslogs-datetime-format" = "%Y-%m-%d %H:%M:%S%L"
      }
    }
    portMappings = [
      {
        containerPort = 9000
        hostPort      = 9000
      }
    ]
  }

  all_containers = concat(
    local.base_containers,
    local.wiz_containers,
    [local.frontend_container]
  )
}
