module "github_oidc_provider" {
  source      = "./tdr-terraform-modules/identity_provider"
  audience    = "sts.amazonaws.com"
  thumbprint  = "6938fd4d98bab03faadb97b34396831e3780aea1"
  url         = "https://token.actions.githubusercontent.com"
  common_tags = local.common_tags
}

module "github_consignment_api_environment" {
  source          = "./tdr-terraform-modules/github_environments"
  environment     = local.environment
  repository_name = "nationalarchives/tdr-consignment-api"
  team_slug       = "transfer-digital-records-admins"
  secrets = {
    ACCOUNT_NUMBER = data.aws_caller_identity.current.account_id
  }
}

module "github_e2e_tests_environment" {
  source          = "./tdr-terraform-modules/github_repositories"
  repository_name = "nationalarchives/tdr-e2e-tests"
  secrets = {
    "${upper(local.environment)}_ACCOUNT_NUMBER"        = data.aws_caller_identity.current.account_id
    "${upper(local.environment)}_USER_ADMIN_SECRET"     = module.keycloak_ssm_parameters.params[local.keycloak_user_admin_client_secret_name].value
    "${upper(local.environment)}_BACKEND_CHECKS_SECRET" = module.keycloak_ssm_parameters.params[local.keycloak_backend_checks_secret_name].value
  }
}

module "github_transfer_frontend_environment" {
  source          = "./tdr-terraform-modules/github_environments"
  environment     = local.environment
  repository_name = "nationalarchives/tdr-transfer-frontend"
  team_slug       = "transfer-digital-records-admins"
  secrets = {
    ACCOUNT_NUMBER = data.aws_caller_identity.current.account_id
  }
}

module "github_keycloak_user_management_environment" {
  source          = "./tdr-terraform-modules/github_environments"
  environment     = local.environment
  repository_name = "nationalarchives/tdr-keycloak-user-management"
  team_slug       = "transfer-digital-records-admins"
  secrets = {
    TITLE_STAGE            = title(local.environment)
    ACCOUNT_NUMBER         = data.aws_caller_identity.current.account_id
    MANAGEMENT_ACCOUNT     = data.aws_ssm_parameter.mgmt_account_number.value
    SLACK_FAILURE_WORKFLOW = data.aws_ssm_parameter.slack_failure_workflow.value
    SLACK_SUCCESS_WORKFLOW = data.aws_ssm_parameter.slack_success_workflow.value
    WORKFLOW_PAT           = data.aws_ssm_parameter.workflow_pat.value
  }
}

module "github_actions_deploy_lambda_policy" {
  source        = "./tdr-terraform-modules/iam_policy"
  name          = "TDRGithubActionsDeployLambda${title(local.environment)}"
  policy_string = templatefile("${path.module}/templates/iam_policy/deploy_lambda_github_actions.json.tpl", { account_id = data.aws_caller_identity.current.account_id, environment = local.environment, region = local.region })
}

module "github_actions_role" {
  source             = "./tdr-terraform-modules/iam_role"
  assume_role_policy = templatefile("${path.module}/templates/iam_role/github_assume_role.json.tpl", { account_id = data.aws_caller_identity.current.account_id, repo_name = "tdr-*" })
  common_tags        = local.common_tags
  name               = "TDRGithubActionsDeployLambda${title(local.environment)}"
  policy_attachments = {
    deploy_lambda = module.github_actions_deploy_lambda_policy.policy_arn
  }
}

module "github_update_waf_and_security_groups_policy" {
  source        = "./tdr-terraform-modules/iam_policy"
  name          = "TDRUpdateWAFAndSecurityGroupsPolicy${title(local.environment)}"
  policy_string = templatefile("${path.module}/templates/iam_policy/update_waf_and_security_groups_policy.json.tpl", { rule_group_arn = module.waf.rule_group_arn, ip_set_arn = module.waf.ip_set_arn, account_id = data.aws_caller_identity.current.account_id, security_group_id = module.frontend.alb_security_group_id })
}

module "github_update_waf_and_security_groups_role" {
  source             = "./tdr-terraform-modules/iam_role"
  assume_role_policy = templatefile("${path.module}/templates/iam_role/github_assume_role.json.tpl", { account_id = data.aws_caller_identity.current.account_id, repo_name = "tdr-e2e-tests" })
  common_tags        = local.common_tags
  name               = "TDRUpdateWAFAndSecurityGroupsRole${title(local.environment)}"
  policy_attachments = {
    update_policy = module.github_update_waf_and_security_groups_policy.policy_arn
  }
}

module "github_update_ecs_policy" {
  source        = "./tdr-terraform-modules/iam_policy"
  name          = "TDRGitHubECSUpdatePolicy${title(local.environment)}"
  policy_string = templatefile("${path.module}/templates/iam_policy/github_update_ecs_policy.json.tpl", { account_id = data.aws_caller_identity.current.account_id, region = local.region, environment = local.environment })
}

module "github_update_ecs_role" {
  source             = "./tdr-terraform-modules/iam_role"
  assume_role_policy = templatefile("${path.module}/templates/iam_role/github_assume_role.json.tpl", { account_id = data.aws_caller_identity.current.account_id, repo_name = "tdr-" })
  common_tags        = local.common_tags
  name               = "TDRGitHubECSUpdateRole${title(local.environment)}"
  policy_attachments = {
    update_ecs_policy = module.github_update_ecs_policy.policy_arn
  }
}
