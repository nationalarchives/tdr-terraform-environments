# TDRD-1268
# Alarms must be created in the management account 
# Naming convention for the alarm should be:
# <metrics_name_space> <why> <resource_triggering_alert>
# This assumes that the resource contains an account identifier.  If not add one in the alarm name

# SNS - Failed notifications
locals {
  topic_prefix = ["tdr-notifications"]
}

resource "aws_cloudwatch_metric_alarm" "tdr_alarms_sns_notifications_failed" {
  for_each          = local.environment == "prod" ? toset(local.topic_prefix) : []
  alarm_description = "This alarm can detect when the number of failed SNS messages is too high"
  alarm_name        = format("AWS/SNS NumberOfNotificationsFailed on %s-%s", each.key, local.environment)

  metric_query {
    account_id  = data.aws_caller_identity.current.id
    id          = "m1"
    return_data = "true"

    metric {
      metric_name = "NumberOfNotificationsFailed"
      namespace   = "AWS/SNS"
      stat        = "Sum"
      period      = 60
      dimensions = {
        TopicName = format("%s-%s", each.key, local.environment)
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
