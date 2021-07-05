locals {
  app_port = 8080
}
resource "aws_ecs_cluster" "keycloak_ecs" {
  name = "keycloak_${var.environment}"

  tags = merge(
    var.common_tags,
    tomap(
      { "Name" = "keycloak_${var.environment}" }
    )
  )
}

data "template_file" "app" {
  template = file("modules/keycloak/templates/keycloak.json.tpl")

  vars = {
    app_image                         = "${data.aws_ssm_parameter.mgmt_account_number.value}.dkr.ecr.eu-west-2.amazonaws.com/auth-server:${var.environment}"
    app_port                          = local.app_port
    app_environment                   = var.environment
    aws_region                        = var.region
    url_path                          = aws_ssm_parameter.database_url.name
    username                          = "keycloak_user"
    password_path                     = aws_ssm_parameter.keycloak_user_password.name
    admin_user_path                   = aws_ssm_parameter.keycloak_admin_user.name
    admin_password_path               = aws_ssm_parameter.keycloak_admin_password.name
    client_secret_path                = aws_ssm_parameter.keycloak_client_secret.name
    backend_checks_client_secret_path = aws_ssm_parameter.keycloak_backend_checks_client_secret.name
    realm_admin_client_secret_path    = aws_ssm_parameter.keycloak_realm_admin_client_secret.name
    frontend_url                      = var.frontend_url
    configuration_properties_path     = aws_ssm_parameter.keycloak_configuration_properties.name
    user_admin_client_secret_path     = aws_ssm_parameter.keycloak_user_admin_client_secret.name
    govuk_notify_api_key_path         = aws_ssm_parameter.keycloak_govuk_notify_api_key.name
    govuk_notify_template_id_path     = aws_ssm_parameter.keycloak_govuk_notify_template_id.name
    reporting_client_secret_path      = aws_ssm_parameter.keycloak_reporting_client_secret.name
  }
}

resource "aws_ecs_task_definition" "keycloak_task" {
  family                   = "${var.app_name}-${var.environment}"
  execution_role_arn       = aws_iam_role.keycloak_ecs_execution.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 3072
  container_definitions    = data.template_file.app.rendered
  task_role_arn            = aws_iam_role.keycloak_ecs_task.arn

  tags = merge(
    var.common_tags,
    tomap(
      { "Name" = "${var.app_name}-task-definition" }
    )
  )
}

resource "aws_ecs_service" "keycloak_service" {
  name                              = "${var.app_name}_service_${var.environment}"
  cluster                           = aws_ecs_cluster.keycloak_ecs.id
  task_definition                   = aws_ecs_task_definition.keycloak_task.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = "360"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.private.*.id
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = var.app_name
    container_port   = 8080
  }

  depends_on = [var.alb_target_group_arn]
}

resource "aws_iam_role" "keycloak_ecs_execution" {
  name               = "keycloak_ecs_execution_role_${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json

  tags = merge(
    var.common_tags,
    tomap(
      { "Name" = "api-ecs-execution-iam-role-${var.environment}" }
    )
  )
}

resource "aws_iam_role" "keycloak_ecs_task" {
  name               = "keycloak_ecs_task_role_${var.environment}"
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

resource "aws_iam_role_policy_attachment" "keycloak_ecs_execution_ssm" {
  role       = aws_iam_role.keycloak_ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "keycloak_ecs_execution" {
  role       = aws_iam_role.keycloak_ecs_execution.name
  policy_arn = aws_iam_policy.keycloak_ecs_execution.arn
}

resource "aws_iam_policy" "keycloak_ecs_execution" {
  name   = "keycloak_ecs_execution_policy_${var.environment}"
  path   = "/"
  policy = data.aws_iam_policy_document.keycloak_ecs_execution.json
}

data "aws_ssm_parameter" "mgmt_account_number" {
  name = "/mgmt/management_account"
}

data "aws_iam_policy_document" "keycloak_ecs_execution" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]
    resources = [
      aws_cloudwatch_log_group.keycloak_log_group.arn,
      "arn:aws:ecr:eu-west-2:${data.aws_ssm_parameter.mgmt_account_number.value}:repository/auth-server"
    ]
  }
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
}
