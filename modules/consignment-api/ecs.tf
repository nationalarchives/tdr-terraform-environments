locals {
  app_port           = 8080
  ecr_account_number = var.environment == "sbox" ? data.aws_caller_identity.current.account_id : data.aws_ssm_parameter.mgmt_account_number.value
  cpu                = var.environment == "intg" ? "512" : "1024"
  memory             = var.environment == "intg" ? "1024" : "2048"

}

resource "aws_ecs_cluster" "consignment_api_ecs" {
  name = "${var.app_name}_${var.environment}"

  tags = merge(
    var.common_tags,
    tomap(
      { "Name" = "consignment_api_${var.environment}" }
    )
  )
}

data "template_file" "app" {
  template = file("${path.module}/templates/consignment-api.json.tpl")

  vars = {
    app_image                    = "${local.ecr_account_number}.dkr.ecr.eu-west-2.amazonaws.com/consignment-api:${var.environment}"
    app_port                     = local.app_port
    app_environment              = var.environment
    aws_region                   = var.region
    url_path                     = "/${var.environment}/consignmentapi/instance/url"
    auth_url                     = var.auth_url
    frontend_url                 = var.frontend_url
    block_assign_file_references = var.block_assign_file_references
    da_reference_generator_url   = var.da_reference_generator_url
    da_reference_generator_limit = var.da_reference_generator_limit
    block_validation_library     = var.block_validation_library
  }
}

resource "aws_ecs_task_definition" "consignment_api_task" {
  family                   = "${var.app_name}-${var.environment}"
  execution_role_arn       = aws_iam_role.consignment_api_ecs_execution.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = local.cpu
  memory                   = local.memory
  container_definitions    = data.template_file.app.rendered
  task_role_arn            = aws_iam_role.consignment_api_ecs_task.arn

  tags = merge(
    var.common_tags,
    tomap(
      { "Name" = "${var.app_name}-task-definition" }
    )
  )
}

resource "aws_ecs_service" "consignment_api_service" {
  name                              = "${var.app_name}_service_${var.environment}"
  cluster                           = aws_ecs_cluster.consignment_api_ecs.id
  task_definition                   = aws_ecs_task_definition.consignment_api_task.arn
  desired_count                     = var.service_tasks_desired_count
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = "360"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = var.backend_checks_subnets
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = var.app_name
    container_port   = local.app_port
  }

  depends_on = [var.alb_target_group_arn]
}

resource "aws_iam_role" "consignment_api_ecs_execution" {
  name               = "${var.app_name}_ecs_execution_role_${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json

  tags = merge(
    var.common_tags,
    tomap(
      { "Name" = "api-ecs-execution-iam-role-${var.environment}" }
    )
  )
}

resource "aws_iam_role_policy_attachment" "assume_iam_auth" {
  policy_arn = aws_iam_policy.consignment_api_ecs_task_allow_iam_auth.arn
  role       = aws_iam_role.consignment_api_ecs_task.id
}

resource "aws_iam_policy" "consignment_api_ecs_task_allow_iam_auth" {
  name   = "TDRConsignmentApiAllowIAMAuthPolicy${title(var.environment)}"
  policy = templatefile("${path.module}/templates/allow_iam_db_auth.json.tpl", { account_id = data.aws_caller_identity.current.account_id, resource_id = var.db_instance_resource_id })
}

resource "aws_iam_role" "consignment_api_ecs_task" {
  name               = "${var.app_name}_ecs_task_role_${var.environment}"
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

data "aws_ssm_parameter" "mgmt_account_number" {
  name = "/mgmt/management_account"
}

data "aws_iam_policy_document" "consignment_api_ecs_execution" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]
    resources = [
      "${aws_cloudwatch_log_group.consignment_api_log_group.arn}:*",
      "arn:aws:ecr:eu-west-2:${local.ecr_account_number}:repository/consignment-api"
    ]
  }
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
}
