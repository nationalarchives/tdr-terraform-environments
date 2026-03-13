# TDRD-1268
# All the infrastructure alarms go here
# Alarms must be created in the management account
# Naming convention for the alarm should be
# <metrics_name space>-<why>-<resource_triggering_alert>

# This assume that the thing contains an account identifier.  If not add one in the alarn name
#
# S3
resource "aws_cloudwatch_metric_alarm" "tdr_alarms_s3_object_put" {
  count             = local.environment == "intg" ? 1 : 0
  alarm_description = "This alarm fires when a object has been put into the bucket"
  alarm_name        = format("AWS/S3 Object Put in tdr-upload-files-%s", local.environment)

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
        BucketName = format("tdr-upload-files-%s", local.environment)
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

