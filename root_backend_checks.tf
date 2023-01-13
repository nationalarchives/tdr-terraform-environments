module "backend_checks_api_role" {
  source             = "./tdr-terraform-modules/iam_role"
  assume_role_policy = templatefile("./templates/iam_policy/assume_role_policy.json.tpl", { service = "apigateway.amazonaws.com" })
  common_tags        = local.common_tags
  name               = "TDRBackendChecksAPIRole${title(local.environment)}"
  policy_attachments = {
    AmazonAPIGatewayPushToCloudWatchLogs = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs",
    AWSStepFunctionsFullAccess           = "arn:aws:iam::aws:policy/AWSStepFunctionsFullAccess"
  }
}

module "backend_checks_api" {
  source = "./tdr-terraform-modules/apigateway"
  api_definition = templatefile("./templates/api_gateway/backend_checks.json.tpl", {
    environment       = local.environment
    title             = "Backend Checks API"
    role_arn          = module.backend_checks_api_role.role.arn
    region            = local.region
    lambda_arn        = module.export_authoriser_lambda.export_api_authoriser_arn
    state_machine_arn = "arn:aws:states:${local.region}:${data.aws_caller_identity.current.account_id}:stateMachine:TDRBackendChecks${title(local.environment)}"

  })
  api_name    = "BackendChecks"
  common_tags = local.common_tags
  environment = local.environment
}
