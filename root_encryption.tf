module "s3_external_kms_key" {
  source   = "./da-terraform-modules/kms"
  key_name = "tdr-s3-external-kms-${local.environment}"
  tags     = local.common_tags
  default_policy_variables = {
    user_roles    = [module.notification_lambda.notifications_lambda_role_arn[0], module.consignment_export_task_role.role.arn]
    ci_roles      = [local.assume_role]
    service_names = ["cloudwatch"]
  }
}
