# TDRD-1268
# Alarms must be created in the management account 
# Naming convention for the alarm should be:
# <metrics_name_space> <why> <resource_triggering_alert>
# This assumes that the resource contains an account identifier.  If not add one in the alarm name

# ECS - alert on any high CPUUtilization
locals {
  prod_clusters_prefix = ["consignmentapi", "frontend_service", "keycloak"]
}

resource "aws_cloudwatch_metric_alarm" "tdr_alarms_ecs_cpu_utilization" {
  for_each          = local.environment == "prod" ? toset(local.prod_clusters_prefix) : []
  alarm_description = "This alarm helps detect a high CPU utilization of the ECS service"
  alarm_name        = format("AWS/ECS CPU Utilization on ServiceName=%s_service_%s ClusterName=%s_%s", each.key, local.environment, each.key, local.environment)

  metric_query {
    account_id  = data.aws_caller_identity.current.id
    id          = "m1"
    return_data = "true"

    metric {
      metric_name = "CPUUtilization"
      namespace   = "AWS/ECS"
      stat        = "Average"
      period      = 60
      dimensions = {
        ServiceName = format("%s_service_%s", each.key, local.environment)
        ClusterName = format("%s_%s", each.key, local.environment)
      }
    }
  }
  evaluation_periods  = 5
  datapoints_to_alarm = 5
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "breaching"

  provider = aws.alarm_deployer
}
