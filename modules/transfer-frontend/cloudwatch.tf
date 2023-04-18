# Set up CloudWatch group and log stream and retain logs for 30 days
resource "aws_cloudwatch_log_group" "frontend_log_group" {
  name              = "/ecs/frontend-${var.environment}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_stream" "tdr_application_log_stream" {
  name           = "tdr-frontend-log-stream-${var.environment}"
  log_group_name = aws_cloudwatch_log_group.frontend_log_group.name
}

resource "aws_cloudwatch_log_group" "aws-otel-collector" {
  name              = "/ecs/aws-otel-collector-${var.environment}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_stream" "tdr_aws-otel-collector_log_stream" {
  name           = "tdr-aws-otel-collector-log-stream-${var.environment}"
  log_group_name = aws_cloudwatch_log_group.aws-otel-collector.name
}
