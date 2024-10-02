locals {
  //Business Analyst Access For TDR
  ba_access_count = local.environment == "prod" ? 0 : 1
}

//Policy common across all Digital Archiving accounts to allow access by common user
module "aws_sso_da_business_analyst_policy" {
  count  = local.ba_access_count
  source = "./da-terraform-modules/iam_policy"
  name   = "AWSSSO_DABusinessAnalyst"
  tags   = local.common_tags
  policy_string = templatefile("./templates/iam_policy/aws_sso_da_business_analyst_policy.json.tpl", {
    environment         = local.environment
    kms_bucket_key_arns = jsonencode([module.s3_external_kms_key.kms_key_arn])
  })
}