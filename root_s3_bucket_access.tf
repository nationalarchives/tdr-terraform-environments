# AWS SSO groups that require access to encrypted s3 buckets need updating with relevant decrypt permissions for KMS s3 Key

locals {
  aws_sso_export_bucket_access_roles   = local.environment == contains(["intg", "prod"], environment) ? (var.admin_sso_export_access_enabled ? [data.aws_ssm_parameter.aws_sso_admin_role.value] : []) : [data.aws_ssm_parameter.aws_sso_admin_role.value]
  aws_sso_internal_bucket_access_roles   = local.environment == contains(["intg", "prod"], environment) ? (var.admin_sso_internal_access_enabled ? [data.aws_ssm_parameter.aws_sso_admin_role.value] : []) : [data.aws_ssm_parameter.aws_sso_admin_role.value]
}

data "aws_ssm_parameter" "aws_sso_admin_role" {
  name       = "/${local.environment}/admin_role"
  depends_on = [module.aws_sso_export_roles_ssm_parameters]
}

data "aws_ssm_parameter" "aws_sso_export_role" {
  name       = "/${local.environment}/export_role"
  depends_on = [module.aws_sso_export_roles_ssm_parameters]
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

# python should just change the boolean. if the boolean is true the change is made in the terraform.
# be careful will boolean toggle it doesnt affect other terraform applies. an additional parametre to link to the action.