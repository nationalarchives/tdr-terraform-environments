# AWS SSO groups that require access to encrypted s3 export buckets need updating with relevant decrypt permissions for KMS s3 Key

locals {
  aws_sso_export_bucket_access_roles = [data.aws_ssm_parameter.aws_sso_admin_role.value, data.aws_ssm_parameter.aws_sso_export_role.value]
}

data "aws_ssm_parameter" "aws_sso_admin_role" {
  name = "/${local.environment}/admin_role"
}

data "aws_ssm_parameter" "aws_sso_export_role" {
  name = "/${local.environment}/export_role"
}

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
