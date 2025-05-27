locals {
  dataload_count                    = local.environment == "prod" ? 0 : 1
  dataload_processing_function_name = "tdr-dataload-processing-${local.environment}"
}

module "dataload_processing_lambda" {
  count           = local.dataload_count
  source          = "./da-terraform-modules/lambda"
  function_name   = local.dataload_processing_function_name
  tags            = local.common_tags
  handler         = "uk.gov.nationalarchives.dataload.processing.DataLoadProcessingLambda::processDataLoad"
  timeout_seconds = 60
  memory_size     = 512
  runtime         = "java21"
  policies = {
    "TDRDataLoadProcessingLambdaPolicy${title(local.environment)}" = templatefile("./templates/iam_policy/dataload_processing_lambda_policy.json.tpl", {
      function_name = local.dataload_processing_function_name
      account_id    = var.tdr_account_number
    })
  }
}
