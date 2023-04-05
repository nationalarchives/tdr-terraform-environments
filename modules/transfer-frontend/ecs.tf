locals {
  app_port = 9000
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
    collector_image                    = "${data.aws_ssm_parameter.mgmt_account_number.value}.dkr.ecr.eu-west-2.amazonaws.com/aws-otel-collector:${var.environment}"
    app_image                          = "${data.aws_ssm_parameter.mgmt_account_number.value}.dkr.ecr.eu-west-2.amazonaws.com/transfer-frontend:${var.environment}"
    app_port                           = local.app_port
    app_environment                    = var.environment
    aws_region                         = var.region
    client_secret_path                 = var.client_secret_path
    export_api_url                     = var.export_api_url
    backend_checks_api_url             = var.backend_checks_api_url
    alb_ip_a                           = var.public_subnet_ranges[0]
    alb_ip_b                           = var.public_subnet_ranges[1]
    auth_url                           = var.auth_url
    block_feature_closure_metadata     = var.block_feature_closure_metadata
    block_feature_descriptive_metadata = var.block_feature_descriptive_metadata
    block_feature_view_transfers       = var.block_feature_view_transfers
  }
}

resource "aws_ecs_task_definition" "frontend_task" {
  family                   = "${var.app_name}-${var.environment}"
  execution_role_arn       = aws_iam_role.frontend_ecs_execution.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
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
      "arn:aws:ecr:eu-west-2:${data.aws_ssm_parameter.mgmt_account_number.value}:repository/transfer-frontend"
    ]
  }
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
}
