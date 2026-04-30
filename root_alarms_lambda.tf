# TDRD-1268
# Alarms must be created in the management account 
# Naming convention for the alarm should be:
# <metrics_name_space> <why> <resource_triggering_alert>
# This assumes that the resource contains an account identifier.  If not add one in the alarm name

# Lambda - alert on any failure on a prod lambda
locals {
  prod_lambdas = [
    "tdr-aggregate-processing-prod",
    "tdr-api-update-v2-prod",
    "tdr-backend-checks-results-prod",
    "tdr-checksum-v2-prod",
    "tdr-database-migrations-prod",
    "tdr-draft-metadata-checks-prod",
    "tdr-draft-metadata-persistence-prod",
    "tdr-export-api-authoriser-prod",
    "tdr-file-checks-prod",
    "tdr-file-format-v2-prod",
    "tdr-file-upload-data-prod",
    "tdr-notifications-prod",
    "tdr-redacted-files-prod",
    "tdr-reporting-prod",
    "tdr-rotate-keycloak-secrets-prod",
    "tdr-signed-cookies-prod",
    "tdr-statuses-prod",
    "tdr-yara-av-v2-prod",
  ]
  mgmt_lambdas = [
    "tdr-notifications-mgmt",
    "tdr-ecr-scan-mgmt"
  ]
}

resource "aws_cloudwatch_metric_alarm" "tdr_alarms_lambda_failure" {
  for_each          = local.environment == "prod" ? toset(concat(local.prod_lambdas, local.mgmt_lambdas)) : []
  alarm_description = "This alarm fires when a lambda fails"
  alarm_name        = format("AWS/Lambda Error on %s", each.key)

  metric_query {
    account_id  = data.aws_caller_identity.current.id
    id          = "m1"
    return_data = "true"

    metric {
      metric_name = "Errors"
      namespace   = "AWS/Lambda"
      stat        = "Sum"
      period      = 60
      dimensions = {
        FunctionName = each.key
      }
    }
  }
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  provider = aws.alarm_deployer
}

resource "aws_cloudwatch_metric_alarm" "tdr_alarms_lambda_throttles" {
  for_each          = local.environment == "prod" ? toset(local.prod_lambdas) : []
  alarm_description = "This alarm detects a high number of throttled invocation requests. Throttling occurs when there is no concurrency available for scale up"
  alarm_name        = format("AWS/Lambda Throttles on %s", each.key)

  metric_query {
    account_id  = data.aws_caller_identity.current.id
    id          = "m1"
    return_data = "true"

    metric {
      metric_name = "Throttles"
      namespace   = "AWS/Lambda"
      stat        = "Sum"
      period      = 60
      dimensions = {
        FunctionName = each.key
      }
    }
  }

  evaluation_periods  = 5
  datapoints_to_alarm = 5
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  provider = aws.alarm_deployer
}

