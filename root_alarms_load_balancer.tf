# TDRD-1268
# Alarms must be created in the management account 
# Naming convention for the alarm should be:
# <metrics_name_space> <why> <resource_triggering_alert>
# This assumes that the resource contains an account identifier.  If not add one in the alarm name

# Load Balancers
# See https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-cloudwatch-metrics.html
locals {
  load_balancers = [module.consignment_api_alb.alb_arn_suffix,
    module.frontend_alb.alb_arn_suffix,
    module.keycloak_tdr_alb.alb_arn_suffix,
    module.transfer_service_tdr_alb[0].alb_arn_suffix
  ]
}

resource "aws_cloudwatch_metric_alarm" "tdr_alarms_elb_4xx_count" {
  for_each          = toset(local.load_balancers)
  alarm_description = "This alarm fires when an ELB (not the target) returns a high number of 4xx errors"
  alarm_name        = format("AWS/ApplicationELB High 4XX Count Environment=%s, LB=%s", local.environment, each.key)

  metric_query {
    account_id  = data.aws_caller_identity.current.id
    id          = "m1"
    return_data = "true"

    metric {
      metric_name = "HTTPCode_ELB_4XX_Count"
      namespace   = "AWS/ApplicationELB"
      stat        = "Sum"
      period      = 60
      dimensions = {
        LoadBalancer = each.key
      }
    }
  }
  evaluation_periods  = 10
  datapoints_to_alarm = 3
  threshold           = 500
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  provider = aws.alarm_deployer
}

resource "aws_cloudwatch_metric_alarm" "tdr_alarms_elb_target_4xx_count" {
  for_each          = toset(local.load_balancers)
  alarm_description = "This alarm fires when an ELB target returns a high number of 4xx errors"
  alarm_name        = format("AWS/ApplicationELB High 4XX Count On Target Environment=%s, LB=%s", local.environment, each.key)

  metric_query {
    account_id  = data.aws_caller_identity.current.id
    id          = "m1"
    return_data = "true"

    metric {
      metric_name = "HTTPCode_Target_4XX_Count"
      namespace   = "AWS/ApplicationELB"
      stat        = "Sum"
      period      = 60
      dimensions = {
        LoadBalancer = each.key
      }
    }
  }
  evaluation_periods  = 5
  datapoints_to_alarm = 5
  threshold           = 50
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  provider = aws.alarm_deployer
}

resource "aws_cloudwatch_metric_alarm" "tdr_alarms_elb_target_5xx_count" {
  for_each          = toset(local.load_balancers)
  alarm_description = "This alarm fires when an ELB target returns a high number of 5xx errors"
  alarm_name        = format("AWS/ApplicationELB High 5XX Count On Target Environment=%s, LB=%s", local.environment, each.key)

  metric_query {
    account_id  = data.aws_caller_identity.current.id
    id          = "m1"
    return_data = "true"

    metric {
      metric_name = "HTTPCode_Target_5XX_Count"
      namespace   = "AWS/ApplicationELB"
      stat        = "Sum"
      period      = 60
      dimensions = {
        LoadBalancer = each.key
      }
    }
  }
  evaluation_periods  = 5
  datapoints_to_alarm = 5
  threshold           = 50
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  provider = aws.alarm_deployer
}
