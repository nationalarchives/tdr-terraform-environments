resource "aws_flow_log" "keycloak_flowlog" {
  iam_role_arn    = aws_iam_role.keycloak_flowlog_role.arn
  log_destination = aws_cloudwatch_log_group.keycloak_flowlog_log_group.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
}

resource "aws_cloudwatch_log_group" "keycloak_flowlog_log_group" {
  name = "/flowlogs/keycloak-vpc-${var.environment}"
  tags = merge(
    var.common_tags,
    tomap(
      {"Name" = "flowlogs/keycloak-vpc-${var.environment}"}
    )
  )
}

resource "aws_iam_role" "keycloak_flowlog_role" {
  name               = "keycloak_flowlog_role_${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.keycloak_flowlog_assume_role_policy.json
  tags = merge(
    var.common_tags,
    tomap(
      {"Name" = "keycloak-flowlog-role-${var.environment}"}
    )
  )
}

data "aws_iam_policy_document" "keycloak_flowlog_assume_role_policy" {
  version = "2012-10-17"
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "keycloak_flowlog_policy" {
  name   = "TDRKeycloakFlowlogPolicy${title(var.environment)}"
  path   = "/"
  policy = data.aws_iam_policy_document.keycloak_flowlog_policy.json
}

data "aws_iam_policy_document" "keycloak_flowlog_policy" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]

    resources = [
      "arn:aws:logs:*:*:log-group:/flowlogs/keycloak-vpc-*"
    ]
  }
}

resource "aws_iam_role_policy_attachment" "keycloak_flowlog_attach" {
  role       = aws_iam_role.keycloak_flowlog_role.name
  policy_arn = aws_iam_policy.keycloak_flowlog_policy.arn
}