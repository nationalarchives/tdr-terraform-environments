# Metrics derived from logs

locals {
  namespace_name = "Log_Metrics"

  # For now SharePoint integration not released to Prod so monitor staging
  sharepoint_metrics_env = "staging"
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

resource "aws_cloudwatch_log_metric_filter" "sharepoint_load_initiated" {
  count          = local.environment == local.sharepoint_metrics_env ? 1 : 0
  name           = "sharepoint_load_initiated"
  pattern        = "\"POST /load/sharepoint/initiate\""
  log_group_name = "/ecs/transfer-service-${local.sharepoint_metrics_env}"

  metric_transformation {
    name      = "SharePoint Load Initiated - ${title(local.sharepoint_metrics_env)}"
    namespace = local.namespace_name
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "sharepoint_load_completed" {
  count          = local.environment == local.sharepoint_metrics_env ? 1 : 0
  name           = "sharepoint_load_completed"
  pattern        = "\"POST /load/sharepoint/complete\""
  log_group_name = "/ecs/transfer-service-${local.sharepoint_metrics_env}"

  metric_transformation {
    name      = "SharePoint Load Completed - ${title(local.sharepoint_metrics_env)}"
    namespace = local.namespace_name
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "sharepoint_asset_metadata_processed_success" {
  count          = local.environment == local.sharepoint_metrics_env ? 1 : 0
  name           = "sharepoint_asset_metadata_processed_success"
  pattern        = "Asset metadata successfully processed for sharepoint .metadata"
  log_group_name = "/aws/lambda/tdr-aggregate-processing-${local.sharepoint_metrics_env}"

  metric_transformation {
    name      = "SharePoint Asset Metadata Proccessed Success - ${title(local.sharepoint_metrics_env)}"
    namespace = local.namespace_name
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "sharepoint_asset_metadata_processed_failed" {
  count          = local.environment == local.sharepoint_metrics_env ? 1 : 0
  name           = "sharepoint_asset_metadata_processed_failed"
  pattern        = "errorCode errorMessage"
  log_group_name = "/aws/lambda/tdr-aggregate-processing-${local.sharepoint_metrics_env}"

  metric_transformation {
    name      = "SharePoint Asset Metadata Proccessed Failed - ${title(local.sharepoint_metrics_env)}"
    namespace = local.namespace_name
    value     = "1"
  }
}
