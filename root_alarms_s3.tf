# TDRD-1268
# Alarms must be created in the management account 
# Naming convention for the alarm should be:
# <metrics_name_space> <why> <resource_triggering_alert>

# This assume that the resource contains an account identifier.  If not add one in the alarm name
#
# S3
resource "aws_cloudwatch_metric_alarm" "tdr_alarms_s3_object_put_quarantine" {
  alarm_description = "This alarm fires when an object has been put into the bucket"
  alarm_name        = format("AWS/S3 Object Put in tdr-upload-files-quarantine-%s", local.environment)

  metric_query {
    account_id  = data.aws_caller_identity.current.id
    id          = "m1"
    return_data = "true"

    metric {
      metric_name = "PutRequests"
      namespace   = "AWS/S3"
      stat        = "Sum"
      period      = 60
      dimensions = {
        BucketName = format("tdr-upload-files-quarantine-%s", local.environment)
        FilterId   = "EntireBucket"
      }
    }
  }
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 1
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "missing"

  provider = aws.alarm_deployer
}

resource "aws_cloudwatch_metric_alarm" "tdr_alarms_s3_object_put_transfer_errors" {
  count             = local.environment == "prod" ? 1 : 0
  alarm_description = "This alarm fires when an object has been put into the bucket"
  alarm_name        = format("AWS/S3 Object Put in tdr-transfer-errors-%s", local.environment)

  metric_query {
    account_id  = data.aws_caller_identity.current.id
    id          = "m1"
    return_data = "true"

    metric {
      metric_name = "PutRequests"
      namespace   = "AWS/S3"
      stat        = "Sum"
      period      = 60
      dimensions = {
        BucketName = format("tdr-transfer-errors-%s", local.environment)
        FilterId   = "EntireBucket"
      }
    }
  }
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 1
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "missing"

  provider = aws.alarm_deployer
}

