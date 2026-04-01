# TDRD-1268 / TDRD-1367
# Alarms must be created in the management account
# Naming convention for the alarm should be:
# <metrics_name_space> <why> <resource_triggering_alert>
# This assumes that the resource contains an account identifier.  If not add one in the alarm name

# AWS/DDoSProtection (AWS Shield)
# https://docs.aws.amazon.com/waf/latest/developerguide/shield-metrics.html
locals {
  shield_protected_resoures = [data.aws_route53_zone.tdr_dns_zone.arn,
    module.cloudfront_upload.cloudfront_arn,
    module.keycloak_tdr_alb.alb_arn,
    module.consignment_api_alb.alb_arn,
    module.frontend_alb.alb_arn,
    module.transfer_service_tdr_alb[0].alb_arn,
    module.shared_vpc.elastic_ip_arns[0],
    module.shared_vpc.elastic_ip_arns[1]
  ]
}

resource "aws_cloudwatch_metric_alarm" "tdr_alarms_shield_ddos_detected" {
  for_each          = toset(local.shield_protected_resoures)
  alarm_description = "Indicates a DDoS event for a specific Amazon Resource Name (ARN)"
  alarm_name        = format("AWS/DDoSProtection DDoSDetected on Environment=%s, LB=%s", local.environment, each.key)

  metric_query {
    account_id  = data.aws_caller_identity.current.id
    id          = "m1"
    return_data = "true"

    metric {
      metric_name = "DDoSDetected"
      namespace   = "AWS/DDoSProtection"
      stat        = "Sum"
      period      = 60
      dimensions = {
        ResourceArn = each.key
      }
    }
  }
  evaluation_periods  = 20
  datapoints_to_alarm = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  provider = aws.alarm_deployer
}
