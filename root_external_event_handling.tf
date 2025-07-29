locals {
  //Apply only to INTG at the moment
  event_handling_count                 = local.environment == "intg" ? 1 : 0
  sqs_name                             = "tdr-external-event-handling-sqs-${local.environment}"
  external_event_handler_function_name = "tdr-external-events-handler-${local.environment}"
  dr2_ingest_topic_arn                 = module.dr2_configuration.terraform_config[local.environment]["notifications_sns_topic_arn"]
  lambda_timeout                       = 60
}

module "external_event_handling_sqs_queue" {
  count      = local.event_handling_count
  source     = "./da-terraform-modules/sqs"
  tags       = local.common_tags
  queue_name = local.sqs_name
  sqs_policy = templatefile("./templates/sqs/external_event_handling_policy.json.tpl", {
    region               = local.region,
    environment          = local.environment,
    account_id           = data.aws_caller_identity.current.account_id,
    sqs_name             = local.sqs_name,
    dr2_account_id       = module.dr2_configuration.account_numbers[local.environment],
    dr2_ingest_topic_arn = local.dr2_ingest_topic_arn
  })
  encryption_type    = "kms"
  kms_key_id         = module.encryption_key.kms_key_arn
  visibility_timeout = 6 * local.lambda_timeout
}

resource "aws_sns_topic_subscription" "dr2_ingest" {
  endpoint             = "arn:aws:sqs:eu-west-2:${var.tdr_account_number}:${local.sqs_name}"
  protocol             = "sqs"
  topic_arn            = local.dr2_ingest_topic_arn
  raw_message_delivery = true
}

module "external_event_handler_lambda" {
  count         = local.event_handling_count
  source        = "./da-terraform-modules/lambda"
  function_name = local.external_event_handler_function_name
  tags          = local.common_tags
  handler       = "uk.gov.nationalarchives.externalevent.Lambda::handleRequest"
  lambda_sqs_queue_mappings = [{
    sqs_queue_arn         = "arn:aws:sqs:eu-west-2:${var.tdr_account_number}:${local.sqs_name}",
    ignore_enabled_status = false
  }]
  timeout_seconds = local.lambda_timeout
  memory_size     = 512
  runtime         = "java21"
  policies = {
    "TDRExternalEventHandlerLambdaPolicy${title(local.environment)}" = templatefile("./templates/iam_policy/external_event_handler_lambda_policy.json.tpl", {
      function_name          = local.external_event_handler_function_name
      account_id             = var.tdr_account_number
      kms_key_id             = module.encryption_key.kms_key_arn
      sqs_queue              = local.sqs_name,
      export_bucket          = local.flat_format_bucket_name,
      judgment_export_bucket = local.flat_format_judgment_bucket_name
    })
  }
  plaintext_env_vars = {
    EXPORT_BUCKET          = local.flat_format_bucket_name,
    JUDGMENT_EXPORT_BUCKET = local.flat_format_judgment_bucket_name,
    DR2_INGEST_TAG_KEY     = local.object_tag_dr2_ingest_key,
    DR2_INGEST_TAG_VALUE   = local.object_tag_dr2_ingest_value_complete,
  }
}
