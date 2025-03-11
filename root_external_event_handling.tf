locals {
  //Apply only to INTG at the moment
  event_handling_count                 = local.environment == "intg" ? 1 : 0
  sqs_name                             = "tdr-external-event-handling-sqs-${local.environment}"
  external_event_handler_function_name = "tdr-external-events-handler-${local.environment}"
}

module "external_event_handling_sqs_queue" {
  count           = local.event_handling_count
  source          = "./da-terraform-modules/sqs"
  tags            = local.common_tags
  queue_name      = local.sqs_name
  sqs_policy      = templatefile("./templates/sqs/external_event_handling_policy.json.tpl", { region = local.region, environment = local.environment, account_id = data.aws_caller_identity.current.account_id, sqs_name = local.sqs_name })
  encryption_type = "kms"
  kms_key_id      = module.encryption_key.kms_key_arn
}

module "external_event_handler_lambda" {
  source          = "./da-terraform-modules/lambda"
  function_name   = local.external_event_handler_function_name
  tags            = local.common_tags
  handler         = "uk.gov.nationalarchives.externalevent.Lambda::handleRequest"
  timeout_seconds = 60
  memory_size     = 512
  runtime         = "java21"
  policies = {
    "TDRExternalEventHandlerLambdaPolicy${title(local.environment)}" = templatefile("./templates/iam_policy/external_event_handler_lambda_policy.json.tpl", {
      function_name = local.external_event_handler_function_name
      account_id         = var.tdr_account_number
    })
  }
}
