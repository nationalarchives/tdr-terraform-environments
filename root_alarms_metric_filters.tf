# Metrics derived from logs

locals {
  namespace_name = "Log_Metrics"
  authentication_alarms_log_groups = tomap({
    transfer-service = "/ecs/transfer-service-${local.environment}"
  frontend = "/ecs/frontend-${local.environment}" })
  alarms_mute_default  = local.environment == "prod" ? "" : "Muted: "
  alarm_prefix_default = "${local.alarms_mute_default}${local.namespace_name}"

  # GOV.UK Notify applies a daily email send limit to the non production Notify service used by dev, intg and staging.
  # Prod has a much higher limit and is not covered by this alarm.
  gov_uk_notify_email_limit_environments = ["dev", "intg", "staging"]
  gov_uk_notify_email_limit_count        = contains(local.gov_uk_notify_email_limit_environments, local.environment) ? 1 : 0
  gov_uk_notify_email_limit_metric_name  = "GOV.UK Notify Daily Email Limit Reached - Notifications - ${title(local.environment)}"
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
resource "aws_cloudwatch_metric_alarm" "consignment_access_denied" {
  alarm_description = "This alarm fires when a user attempts to load a consignment but is denied access due to permissions"
  alarm_name        = format("${local.alarm_prefix_default}/TransferService/Consignment Access Denied - Environment=%s", title(local.environment))

  metric_query {
    account_id  = data.aws_caller_identity.current.id
    id          = "m1"
    return_data = "true"

    metric {
      metric_name = "Consignment Access Denied - Transfer Service - ${title(local.environment)}"
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
resource "aws_cloudwatch_log_metric_filter" "consignment_access_denied" {
  name           = "consignment-access-denied-${local.environment}"
  pattern        = local.error_pattern_consignment_access_denied
  log_group_name = "/ecs/transfer-service-${local.environment}"

  metric_transformation {
    name      = "Consignment Access Denied - Transfer Service - ${title(local.environment)}"
    namespace = local.namespace_name
    value     = "1"
  }
}
# TDRD-1554
# GOV.UK Notify rejects email send requests with a 429 "TooManyRequestsError" once the daily send limit for the
# environment has been used up, e.g.
# {"errors":[{"error":"TooManyRequestsError","message":"Exceeded send limits (email: 50) for today"}],"status_code":429}
# The notifications lambda logs this response for every subsequent send attempt, so the alarm is evaluated over a
# single 24 hour period. The alarm therefore moves to ALARM on the first rejection of the day, stays in ALARM for the
# rest of that day no matter how many further rejections are logged, and resets to OK once the limit resets.
# This alarm is deliberately not prefixed with "Muted: " so that the team is notified in the test environments.
resource "aws_cloudwatch_log_metric_filter" "gov_uk_notify_email_limit_reached" {
  count          = local.gov_uk_notify_email_limit_count
  name           = "gov-uk-notify-email-limit-reached-${local.environment}"
  pattern        = "\"TooManyRequestsError\" \"Exceeded send limits (email\""
  log_group_name = "/aws/lambda/tdr-notifications-${local.environment}"

  metric_transformation {
    name      = local.gov_uk_notify_email_limit_metric_name
    namespace = local.namespace_name
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "gov_uk_notify_email_limit_reached" {
  count             = local.gov_uk_notify_email_limit_count
  alarm_description = "This alarm fires the first time the GOV.UK Notify daily email send limit is reached in the ${title(local.environment)} environment. No further TDR emails will be sent from this environment until the limit resets at midnight UTC."
  alarm_name        = format("${local.namespace_name}/Notifications/GOV.UK Notify Daily Email Limit Reached - Environment=%s", title(local.environment))

  metric_query {
    account_id  = data.aws_caller_identity.current.id
    id          = "m1"
    return_data = "true"

    metric {
      metric_name = local.gov_uk_notify_email_limit_metric_name
      namespace   = local.namespace_name
      stat        = "Sum"
      period      = 86400
    }
  }
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  provider = aws.alarm_deployer
}
