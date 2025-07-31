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

module "akka_licence_key_ssm_parameters" {
  source = "./da-terraform-modules/ssm_parameter"
  parameters = [
    {
      name        = local.akka_licence_key_name,
      description = "Licence key for Akka"
      type        = "SecureString"
      value       = "nonProdDummyLicenceKey"
    }
  ]
  tags = merge(local.common_tags, local.manual_input_tag)
}

module "bau_slack_channel_ssm_parameter" {
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

module "transfers_slack_channel_ssm_parameter" {
  source = "./da-terraform-modules/ssm_parameter"
  parameters = [
    {
      name        = local.slack_transfers_webhook,
      description = "Webhook for TDR transfers slack channel. Value to be added manually"
      type        = "SecureString"
      value       = "To be manually added"
    }
  ]
  tags = merge(local.common_tags, local.manual_input_tag)
}

