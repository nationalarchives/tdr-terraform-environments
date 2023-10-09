module "s3_external_kms_key" {
  source   = "./da-terraform-modules/kms"
  key_name = "tdr-s3-external-kms-${local.environment}"
  tags     = local.common_tags
  default_policy_variables = {
    user_roles = concat([
      module.notification_lambda.notifications_lambda_role_arn[0],
      module.consignment_export_task_role.role.arn,
      local.tre_export_role_arn,
      module.export_bucket_access_role.role_arn
    ], local.aws_sso_export_bucket_access_roles)
    ci_roles      = [local.assume_role]
    service_names = ["cloudwatch"]
  }
}
