locals {
  app_port = 9000
  cpu      = var.environment == "intg" ? "512" : "1024"
  memory   = var.environment == "intg" ? "1024" : "2048"
}
resource "aws_ecs_cluster" "frontend_ecs" {
  name = "frontend_${var.environment}"

  tags = merge(
    var.common_tags,
    tomap(
      { "Name" = "frontend_${var.environment}" }
    )
  )
}

data "aws_caller_identity" "current" {}

data "template_file" "app" {
  template = file("modules/transfer-frontend/templates/frontend.json.tpl")

  vars = {
    collector_image                   = "${data.aws_ssm_parameter.mgmt_account_number.value}.dkr.ecr.eu-west-2.amazonaws.com/aws-otel-collector:${var.environment}"
    app_image                         = "${data.aws_ssm_parameter.mgmt_account_number.value}.dkr.ecr.eu-west-2.amazonaws.com/transfer-frontend:${var.environment}"
    app_port                          = local.app_port
    app_environment                   = var.environment
    aws_region                        = var.region
    client_secret_path                = var.client_secret_path
    export_api_url                    = var.export_api_url
    backend_checks_api_url            = var.backend_checks_api_url
    alb_ip_a                          = var.public_subnet_ranges[0]
    alb_ip_b                          = var.public_subnet_ranges[1]
    auth_url                          = var.auth_url
    otel_service_name                 = var.otel_service_name
    block_draft_metadata_upload       = var.block_draft_metadata_upload
    draft_metadata_validator_api_url  = var.draft_metadata_validator_api_url
    draft_metadata_s3_bucket_name     = var.draft_metadata_s3_bucket_name
    block_automate_judgment_transfers = var.block_automate_judgment_transfers
    notification_sns_topic_arn        = var.notification_sns_topic_arn
  }
}

resource "aws_ecs_task_definition" "frontend_task" {
  family                   = "${var.app_name}-${var.environment}"
  execution_role_arn       = aws_iam_role.frontend_ecs_execution.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = local.cpu
  memory                   = local.memory
  container_definitions    = data.template_file.app.rendered
  task_role_arn            = aws_iam_role.frontend_ecs_task.arn

  tags = merge(
    var.common_tags,
    tomap(
      { "Name" = "${var.app_name}-task-definition" }
    )
  )
}

resource "aws_ecs_service" "frontend_service" {
  name                              = "${var.app_name}_service_${var.environment}"
  cluster                           = aws_ecs_cluster.frontend_ecs.id
  task_definition                   = aws_ecs_task_definition.frontend_task.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = "360"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = var.private_subnets
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = var.app_name
    container_port   = 9000
  }

  depends_on = [var.alb_target_group_arn]
}


resource "aws_iam_role" "frontend_ecs_execution" {
  name               = "frontend_ecs_execution_role_${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json

  tags = merge(
    var.common_tags,
    tomap(
      { "Name" = "api-ecs-execution-iam-role-${var.environment}" }
    )
  )
}

resource "aws_iam_role" "frontend_ecs_task" {
  name               = "frontend_ecs_task_role_${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json

  tags = merge(
    var.common_tags,
    tomap(
      { "Name" = "api-ecs-task-iam-role-${var.environment}" }
    )
  )
}

data "aws_iam_policy_document" "ecs_assume_role" {
  version = "2012-10-17"

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "sns_notifications_publish" {
  statement {
    actions   = ["sns:Publish"]
    resources = [var.notification_sns_topic_arn]
  }
}

resource "aws_iam_policy" "frontend_sns_notifications_publish" {
  name   = "TDRFrontendSNSPublishPolicy${title(var.environment)}"
  policy = data.aws_iam_policy_document.sns_notifications_publish.json
}

resource "aws_iam_role_policy_attachment" "frontend_ecs_task_sns_publish" {
  role       = aws_iam_role.frontend_ecs_task.name
  policy_arn = aws_iam_policy.frontend_sns_notifications_publish
}

resource "aws_iam_role_policy_attachment" "frontend_ecs_task_xray" {
  role       = aws_iam_role.frontend_ecs_task.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayFullAccess"
}

resource "aws_iam_role_policy_attachment" "frontend_ecs_task_ecs_execution" {
  role       = aws_iam_role.frontend_ecs_task.name
  policy_arn = aws_iam_policy.frontend_ecs_execution.arn
}

resource "aws_iam_role_policy_attachment" "frontend_ecs_execution_ssm" {
  role       = aws_iam_role.frontend_ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "frontend_ecs_execution" {
  role       = aws_iam_role.frontend_ecs_execution.name
  policy_arn = aws_iam_policy.frontend_ecs_execution.arn
}

resource "aws_iam_policy" "frontend_ecs_execution" {
  name   = "frontend_ecs_execution_policy_${var.environment}"
  path   = "/"
  policy = data.aws_iam_policy_document.frontend_ecs_execution.json
}

resource "aws_iam_policy" "frontend_draft_metadata" {
  name = "TDRFrontendEcsDraftMetadata${title(var.environment)}"
  policy = templatefile(
    "modules/transfer-frontend/templates/draft_metadata_policy.json.tpl", {
      environment         = var.environment,
      titleEnvironment    = title(var.environment),
      account             = data.aws_caller_identity.current.account_id,
      kms_bucket_key_arns = var.draft_metadata_s3_kms_keys
  })
}

resource "aws_iam_role_policy_attachment" "frontend_draft_metadata" {
  role       = aws_iam_role.frontend_ecs_task.name
  policy_arn = aws_iam_policy.frontend_draft_metadata.arn
}

data "aws_ssm_parameter" "mgmt_account_number" {
  name = "/mgmt/management_account"
}

data "aws_iam_policy_document" "frontend_ecs_execution" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]
    resources = [
      "${aws_cloudwatch_log_group.frontend_log_group.arn}:*",
      "arn:aws:ecr:eu-west-2:${data.aws_ssm_parameter.mgmt_account_number.value}:repository/transfer-frontend",
      "${aws_cloudwatch_log_group.aws-otel-collector.arn}:*",
      "arn:aws:ecr:eu-west-2:${data.aws_ssm_parameter.mgmt_account_number.value}:repository/aws-otel-collector",
      "arn:aws:logs:eu-west-2:${data.aws_caller_identity.current.account_id}:log-group:/aws/ecs/application/metrics:log-stream:otel-stream-*",
      "arn:aws:logs:eu-west-2:${data.aws_caller_identity.current.account_id}:log-group:/aws/events/ecs-task-events-${var.environment}:*"
    ]
  }
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
}
