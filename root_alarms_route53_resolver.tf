# TDRD-1268
# Alarms must be created in the management account 
# Naming convention for the alarm should be:
# <metrics_name_space> <why> <resource_triggering_alert>
# This assumes that the resource contains an account identifier.  If not add one in the alarm name

# Route53/Resolver - Alert when a domain lookup is attempted that is not on the allowlist 

resource "aws_cloudwatch_metric_alarm" "tdr_alarms_r53_resolver_lookup_not_on_allowlist" {

  alarm_description = "This alarm fires when a domain lookup was performed on a domain not in the allowlist"

  alarm_name = format("AWS/Route53Resolver DNS Lookup not on allowlist in Environment=%s", local.environment)

  metric_query {
    account_id  = data.aws_caller_identity.current.id
    id          = "m1"
    return_data = "true"

    metric {
      metric_name = "FirewallRuleQueryVolume"
      namespace   = "AWS/Route53Resolver"
      stat        = "Sum"
      period      = 60
      dimensions = {
        FirewallRuleGroupId  = module.r53_firewall.walled_garden_rule_group.id
        FirewallDomainListId = module.r53_firewall.all_domains_domains_list.id
      }
    }
  }
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "missing"

  provider = aws.alarm_deployer
}
