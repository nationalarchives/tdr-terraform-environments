# Metrics derived from logs

locals {
  namespace_name = "Log_Metrics"
  authentication_alarms_log_groups = tomap({
    transfer-service = "/ecs/transfer-service-${local.environment}"
  frontend = "/ecs/frontend-${local.environment}" })
  alarms_mute_default  = local.environment == "prod" ? "" : "Muted: "
  alarm_prefix_default = "${local.alarms_mute_default}${local.namespace_name}"
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

resource "aws_cloudwatch_metric_alarm" "misconfigured_user_no_transferring_body" {
  for_each          = local.authentication_alarms_log_groups
  alarm_description = "This alarm fires when a TDR user with no transferring body assigned interacts with TDR"
  alarm_name        = format("${local.alarm_prefix_default}/MisconfiguredUser/No Transferring Body - Service=%s Environment=%s", title(each.key), title(local.environment))

  metric_query {
    account_id  = data.aws_caller_identity.current.id
    id          = "m1"
    return_data = "true"

    metric {
      metric_name = "Misconfigured User - no transferring body - ${each.key} - ${title(local.environment)}"
      namespace   = local.namespace_name
      stat        = "Sum"
      period      = 60
    }
  }
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  provider = aws.alarm_deployer
}

resource "aws_cloudwatch_log_metric_filter" "misconfigured_user_no_transferring_body" {
  for_each       = local.authentication_alarms_log_groups
  name           = "misconfigured-user-no-transferring-body-${local.environment}-${each.key}"
  pattern        = "not assigned to a transferring body"
  log_group_name = each.value

  metric_transformation {
    name      = "Misconfigured User - no transferring body - ${each.key} - ${title(local.environment)}"
    namespace = local.namespace_name
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "sharepoint_load_initiated" {
  name           = "sharepoint_load_initiated"
  pattern        = "\"POST /load/sharepoint/initiate\""
  log_group_name = "/ecs/transfer-service-${local.environment}"

  metric_transformation {
    name      = "SharePoint Load Initiated - ${title(local.environment)}"
    namespace = local.namespace_name
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "sharepoint_load_completed" {
  name           = "sharepoint_load_completed"
  pattern        = "\"POST /load/sharepoint/complete\""
  log_group_name = "/ecs/transfer-service-${local.environment}"

  metric_transformation {
    name      = "SharePoint Load Completed - ${title(local.environment)}"
    namespace = local.namespace_name
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "sharepoint_asset_metadata_processed_success" {
  name           = "sharepoint_asset_metadata_processed_success"
  pattern        = "Asset metadata successfully processed for sharepoint .metadata"
  log_group_name = "/aws/lambda/tdr-aggregate-processing-${local.environment}"

  metric_transformation {
    name      = "SharePoint Asset Metadata Proccessed Success - ${title(local.environment)}"
    namespace = local.namespace_name
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "sharepoint_asset_metadata_processed_failed" {
  name           = "sharepoint_asset_metadata_processed_failed"
  pattern        = "errorCode errorMessage"
  log_group_name = "/aws/lambda/tdr-aggregate-processing-${local.environment}"

  metric_transformation {
    name      = "SharePoint Asset Metadata Proccessed Failed - ${title(local.environment)}"
    namespace = local.namespace_name
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "max_transfers_without_series" {
  alarm_description = "This alarm fires when a TDR user attempts a transfer initiation but has more than ${local.max_consignments_without_series} consignments without a series"
  alarm_name        = format("${local.alarm_prefix_default}/TransferService/Maximum Transfers Without Series - Environment=%s", title(local.environment))

  metric_query {
    account_id  = data.aws_caller_identity.current.id
    id          = "m1"
    return_data = "true"

    metric {
      metric_name = "Maximum Transfers Without Series - Transfer Service - ${title(local.environment)}"
      namespace   = local.namespace_name
      stat        = "Sum"
      period      = 60
    }
  }
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  provider = aws.alarm_deployer
}

resource "aws_cloudwatch_log_metric_filter" "max_transfers_without_series" {
  name           = "max-transfers-without-series-${local.environment}"
  pattern        = local.error_pattern_transfers_without_series
  log_group_name = "/ecs/transfer-service-${local.environment}"

  metric_transformation {
    name      = "Maximum Transfers Without Series - Transfer Service - ${title(local.environment)}"
    namespace = local.namespace_name
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "upload_state_incorrect" {
  alarm_description = "This alarm fires when a TDR user attempts an upload where the state is incorrect"
  alarm_name        = format("${local.alarm_prefix_default}/TransferService/Upload State Incorrect - Environment=%s", title(local.environment))

  metric_query {
    account_id  = data.aws_caller_identity.current.id
    id          = "m1"
    return_data = "true"

    metric {
      metric_name = "Upload State Incorrect - Transfer Service - ${title(local.environment)}"
      namespace   = local.namespace_name
      stat        = "Sum"
      period      = 60
    }
  }
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  provider = aws.alarm_deployer
}

resource "aws_cloudwatch_log_metric_filter" "upload_state_incorrect" {
  name           = "upload-state-incorrect-${local.environment}"
  pattern        = local.error_pattern_incorrect_upload_state
  log_group_name = "/ecs/transfer-service-${local.environment}"

  metric_transformation {
    name      = "Upload State Incorrect - Transfer Service - ${title(local.environment)}"
    namespace = local.namespace_name
    value     = "1"
  }
}
