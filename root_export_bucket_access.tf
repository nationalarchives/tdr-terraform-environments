
module "aws_sso_export_roles_ssm_parameters" {
  source = "./da-terraform-modules/ssm_parameter"
  parameters = [
    {
      name        = "/${local.environment}/admin_role",
      description = "AWS SSO admin role. Value to be added manually"
      type        = "SecureString"
      value       = "placeholder"
    },
    {
      name        = "/${local.environment}/developer_role",
      description = "AWS SSO developer role. Value to be added manually"
      type        = "SecureString"
      value       = "placeholder"
    },
    {
      name        = "/${local.environment}/export_role",
      description = "AWS SSO export role. Value to be added manually"
      type        = "SecureString"
      value       = "placeholder"
    }
  ]
  tags = local.common_tags
}

module "export_bucket_access_policy" {
  source = "./da-terraform-modules/iam_policy"
  name   = "TDRExportBucketAccessPolicy${title(local.environment)}"
  policy_string = templatefile("./templates/iam_policy/export_bucket_access_policy.json.tpl", {
    account_id                = data.aws_caller_identity.current.account_id,
    kms_export_bucket_key_arn = module.s3_external_kms_key.kms_key_arn
    environment               = local.environment
  })
}

module "export_bucket_access_role" {
  source = "./da-terraform-modules/iam_role"
  assume_role_policy = templatefile("./templates/iam_policy/assume_role_principal_policy.json.tpl", {
    export_access_principals = local.aws_sso_export_bucket_access_roles
  })
  name = "TDRExportBucketAccessRole${title(local.environment)}"
  policy_attachments = {
    ExportBucketAccess = module.export_bucket_access_policy.policy_arn
  }
  tags = local.common_tags
}
