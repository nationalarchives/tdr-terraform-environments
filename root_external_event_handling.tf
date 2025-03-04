locals {
  //Apply only to INTG at the moment
  event_handling_count = local.environment == "intg" ? 1 : 0
  sqs_name             = "tdr-external-event-handling-sqs-${local.environment}"
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
