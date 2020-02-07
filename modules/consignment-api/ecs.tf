locals {
  app_port = 8080
}
resource "aws_ecs_cluster" "consignment_api_ecs" {
  name = "${var.app_name}_${var.environment}"

  tags = merge(
    var.common_tags,
    map("Name", "consignment_api_${var.environment}")
  )
}

data "template_file" "app" {
  template = file("modules/consignment-api/templates/consignment-api.json.tpl")

  vars = {
    app_image       = "nationalarchives/consignment-api:${var.environment}"
    app_port        = local.app_port
    app_environment = var.environment
    aws_region      = var.region
    url_path        = aws_ssm_parameter.database_url.name
    username_path   = aws_ssm_parameter.database_username.name
    password_path   = aws_ssm_parameter.database_password.name
    auth_url        = var.auth_url
  }
}

resource "aws_ecs_task_definition" "consignment_api_task" {
  family                   = "${var.app_name}-${var.environment}"
  execution_role_arn       = aws_iam_role.consignment_api_ecs_execution.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  container_definitions    = data.template_file.app.rendered
  task_role_arn            = aws_iam_role.consignment_api_ecs_task.arn

  tags = merge(
    var.common_tags,
    map("Name", "${var.app_name}-task-definition")
  )
}

resource "aws_ecs_service" "consignment_api_service" {
  name                              = "${var.app_name}_service_${var.environment}"
  cluster                           = aws_ecs_cluster.consignment_api_ecs.id
  task_definition                   = aws_ecs_task_definition.consignment_api_task.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = "360"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = var.private_subnets
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.consignment_api_target.arn
    container_name   = var.app_name
    container_port   = local.app_port
  }
}


resource "aws_iam_role" "consignment_api_ecs_execution" {
  name               = "${var.app_name}_ecs_execution_role_${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json

  tags = merge(
    var.common_tags,
    map(
      "Name", "api-ecs-execution-iam-role-${var.environment}",
    )
  )
}

resource "aws_iam_role" "consignment_api_ecs_task" {
  name               = "${var.app_name}_ecs_task_role_${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json

  tags = merge(
    var.common_tags,
    map(
      "Name", "api-ecs-task-iam-role-${var.environment}",
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

resource "aws_iam_role_policy_attachment" "consignment_api_ecs_execution_ssm" {
  role       = aws_iam_role.consignment_api_ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "consignment_api_ecs_execution" {
  role       = aws_iam_role.consignment_api_ecs_execution.name
  policy_arn = aws_iam_policy.consignment_api_ecs_execution.arn
}

resource "aws_iam_policy" "consignment_api_ecs_execution" {
  name   = "${var.app_name}_ecs_execution_policy_${var.environment}"
  path   = "/"
  policy = data.aws_iam_policy_document.consignment_api_ecs_execution.json
}

data "aws_iam_policy_document" "consignment_api_ecs_execution" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [aws_cloudwatch_log_group.consignment_api_log_group.arn]
  }
}
