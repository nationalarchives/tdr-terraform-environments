resource "aws_iam_role" "lambda_assume_role" {
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_document.json
  name               = "TDRDbMigrationLambdaRole${title(var.environment)}"
}

data "aws_iam_policy_document" "lambda_assume_role_document" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "lambda_migration_policy" {
  name   = "TDRDbMigrationLambdaPolicy${title(var.environment)}"
  policy = templatefile("${path.module}/templates/migration_lambda.json.tpl", { account_id = data.aws_caller_identity.current.account_id, cluster_id = var.db_cluster_id, log_group_arn = "${aws_cloudwatch_log_group.db_migration_log_group.arn}:*" })
}

resource "aws_iam_role_policy_attachment" "lambda_role_attach_migration_policy" {
  policy_arn = aws_iam_policy.lambda_migration_policy.arn
  role       = aws_iam_role.lambda_assume_role.name
}

resource "aws_lambda_function" "database_migration_function" {
  function_name = "tdr-database-migrations-${var.environment}"
  handler       = "migration.Main::runMigration"
  role          = aws_iam_role.lambda_assume_role.arn
  runtime       = "java11"
  filename      = "${path.module}/temp.zip"
  memory_size   = 512
  timeout       = 60
  vpc_config {
    security_group_ids = [aws_security_group.db_migration.id]
    subnet_ids         = var.private_subnets
  }
  environment {
    variables = {
      DB_HOST = var.db_url
    }
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_role_attach_migration_policy]
}

resource "aws_security_group" "db_migration" {
  name        = "db-migration-security-group-${var.environment}"
  description = "Controls access to the keycloak load balancer"
  vpc_id      = var.vpc_id

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.common_tags,
    tomap(
      { "Name" = "db-migration-security-group-${var.environment}" }
    )
  )
}

resource "aws_cloudwatch_log_group" "db_migration_log_group" {
  name              = "/aws/lambda/tdr-database-migrations-${var.environment}"
  retention_in_days = 30
}
