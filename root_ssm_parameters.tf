locals {

  manual_input_tag = tomap(
    {
      "ManualInput" = true
    }
  )

}

module "reporting_lambda_ssm_parameters" {
  source = "./da-terraform-modules/ssm_parameter"
  parameters = [
    {
      name        = local.tdr_reporting_slack_channel_id,
      description = "Slack channel id where reports will be sent. Value to be added manually"
      type        = "SecureString"
      value       = "To be manually added"
    }
  ]
  tags = merge(local.common_tags, local.manual_input_tag)
}

module "akka_licence_token_ssm_parameters" {
  source = "./da-terraform-modules/ssm_parameter"
  parameters = [
    {
      name        = local.akka_licence_token_name,
      description = "Licence token for Akka"
      type        = "SecureString"
      value       = "To be manually added"
    }
  ]
  tags = merge(local.common_tags, local.manual_input_tag)
}

module "bau_slack_channel_ssm_parameters" {
  source = "./da-terraform-modules/ssm_parameter"
  parameters = [
    {
      name        = local.slack_bau_webhook,
      description = "Webhook for TDR BAU Developer slack channel. Value to be added manually"
      type        = "SecureString"
      value       = "To be manually added"
    }
  ]
  tags = merge(local.common_tags, local.manual_input_tag)

}

