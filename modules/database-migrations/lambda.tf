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

data "aws_iam_policy_document" "lambda_migration_document" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::tdr-database-migrations/*",
      "arn:aws:s3:::tdr-database-migrations"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeInstances",
      "ec2:CreateNetworkInterface",
      "ec2:AttachNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "autoscaling:CompleteLifecycleAction"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda_migration_policy" {
  name   = "TDRDbMigrationLambdaPolicy${title(var.environment)}"
  policy = data.aws_iam_policy_document.lambda_migration_document.json
}

resource "aws_iam_role_policy_attachment" "lambda_role_attach_migration_policy" {
  policy_arn = aws_iam_policy.lambda_migration_policy.arn
  role       = aws_iam_role.lambda_assume_role.name
}

resource "aws_lambda_function" "database_migration_function" {
  function_name = "tdr-database-migrations-${var.environment}"
  handler       = "migration.Main::runMigration"
  role          = aws_iam_role.lambda_assume_role.arn
  runtime       = "java8"
  filename      = "${path.module}/temp.zip"
  memory_size   = 128
  timeout       = 60
  vpc_config {
    security_group_ids = [aws_security_group.db_migration.id]
    subnet_ids         = var.private_subnets
  }
  environment {
    variables = {
      DB_URL      = "jdbc:mysql://${var.db_url}"
      DB_USER     = var.db_user
      DB_PASSWORD = var.db_password
      STAGE       = var.environment
    }
  }
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
    map("Name", "db-migration-security-group-${var.environment}")
  )
}
