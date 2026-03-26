# Metrics derived from logs

locals {
  namespace_name = "Log_Metrics"
}

resource "aws_cloudwatch_log_metric_filter" "consignment_export_success" {
  count          = local.environment == "prod" ? 1 : 0
  name           = "consignment_export_success"
  pattern        = "\"Updated consignment status 'Export' as Completed for consignment\""
  log_group_name = "/ecs/consignment-export-prod"

  metric_transformation {
    name      = "Consignment_Export_Success"
    namespace = local.namespace_name
    value     = "1"
  }
}
