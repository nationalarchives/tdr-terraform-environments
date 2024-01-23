# Set up CloudWatch group and log stream and retain logs for 30 days
resource "aws_cloudwatch_log_group" "frontend_log_group" {
  name              = "/ecs/frontend-${var.environment}"
  retention_in_days = var.cloudwatch_log_retention_days
}

resource "aws_cloudwatch_log_stream" "tdr_application_log_stream" {
  name           = "tdr-frontend-log-stream-${var.environment}"
  log_group_name = aws_cloudwatch_log_group.frontend_log_group.name
}

resource "aws_cloudwatch_log_group" "aws-otel-collector" {
  name              = "/ecs/aws-otel-collector-${var.environment}"
  retention_in_days = var.cloudwatch_log_retention_days
}
# The log group name should match the name in the config for the container: https://github.com/nationalarchives/tdr-xray-logging/blob/main/config.yml#L30
resource "aws_cloudwatch_log_group" "aws-application-metrics" {
  name              = "/aws/ecs/application/metrics"
  retention_in_days = 1
}
