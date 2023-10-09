
module "aws_sso_export_roles_ssm_parameters" {
  source = "./da-terraform-modules/ssm_parameter"
  parameters = [
    {
      name        = "${local.environment}/admin_role",
      description = "AWS SSO admin role. Value to be added manually"
      type        = "SecureString"
      value       = "placeholder"
    },
    {
      name        = "${local.environment}/developer_role",
      description = "AWS SSO developer role. Value to be added manually"
      type        = "SecureString"
      value       = "placeholder"
    },
    {
      name        = "${local.environment}/export_role",
      description = "AWS SSO export role. Value to be added manually"
      type        = "SecureString"
      value       = "placeholder"
    }
  ]
  tags = local.common_tags
}
