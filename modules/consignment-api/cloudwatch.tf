# Set up CloudWatch group and log stream and retain logs for 30 days
resource "aws_cloudwatch_log_group" "consignment_api_log_group" {
  name              = "/ecs/consignment-api-${var.environment}"
  retention_in_days = var.cloudwatch_log_retention_days
}

resource "aws_cloudwatch_log_stream" "consignment_api_log_stream" {
  name           = "tdr-consignment-api-log-stream-${var.environment}"
  log_group_name = aws_cloudwatch_log_group.consignment_api_log_group.name
}