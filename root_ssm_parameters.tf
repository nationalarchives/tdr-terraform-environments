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

module "s3_put_request_header_acl_ssm_parameter" {
  source = "./da-terraform-modules/ssm_parameter"
  parameters = [
    {
      name         = local.s3_put_request_header_acl_parameter,
      description  = "S3 put request 'ACL' header value"
      type         = "String"
      value        = "bucket-owner-full-control"
      ignore_value = true
    }
  ]
  tags = merge(local.common_tags)
}

module "s3_put_request_header_if_none_match_ssm_parameter" {
  source = "./da-terraform-modules/ssm_parameter"
  parameters = [
    {
      name         = local.s3_put_request_header_if_none_match_parameter,
      description  = "S3 put request 'If-None-Match' header value"
      type         = "String"
      value        = "*"
      ignore_value = true
    }
  ]
  tags = merge(local.common_tags)
}
