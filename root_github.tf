module "github_update_waf_and_security_groups_policy" {
  source = "./tdr-terraform-modules/iam_policy"
  name   = "TDRUpdateWAFAndSecurityGroupsPolicy${title(local.environment)}"
  policy_string = templatefile("${path.module}/templates/iam_policy/update_waf_and_security_groups_policy.json.tpl", {
    rule_group_arn    = module.waf.rule_group_arn,
    ip_set_arn        = module.waf.ip_set_arn,
    account_id        = data.aws_caller_identity.current.account_id,
    security_group_id = module.frontend.alb_security_group_id
    environment       = local.environment
  })
}

module "github_update_waf_and_security_groups_blocked_ips_policy" {
  source = "./tdr-terraform-modules/iam_policy"
  name   = "TDRUpdateWAFAndSecurityGroupsBlockedIPsPolicy${title(local.environment)}"
  policy_string = templatefile("${path.module}/templates/iam_policy/update_waf_and_security_groups_policy.json.tpl", {
    rule_group_arn    = module.waf.block_ips_rule_group_arn,
    ip_set_arn        = module.waf.blocked_ip_set_arn,
    account_id        = data.aws_caller_identity.current.account_id,
    security_group_id = module.frontend.alb_security_group_id
    environment       = local.environment
  })
}

module "github_update_waf_and_security_groups_role" {
  source = "./tdr-terraform-modules/iam_role"
  assume_role_policy = templatefile("${path.module}/templates/iam_role/github_assume_role.json.tpl", {
    account_id = data.aws_caller_identity.current.account_id,
    repo_names = jsonencode(concat(module.global_parameters.github_tdr_active_repositories, module.global_parameters.github_da_active_repositories))
  })
  common_tags = local.common_tags
  name        = "TDRUpdateWAFAndSecurityGroupsRole${title(local.environment)}"
  policy_attachments = {
    update_policy = module.github_update_waf_and_security_groups_policy.policy_arn
  }
}

module "github_run_keycloak_update_policy" {
  source = "./tdr-terraform-modules/iam_policy"
  name   = "TDRGitHubRunKeycloakUpdatePolicy${title(local.environment)}"
  policy_string = templatefile("${path.module}/templates/iam_policy/github_run_ecs_policy.json.tpl", {
    task_definition_arn = module.run_keycloak_update_ecs.task_definition_arn,
    cluster_arn         = module.run_keycloak_update_ecs.cluster_arn,
    role_arns           = "\"${module.run_update_keycloak_execution_role.role.arn}\""
  })
}


module "github_run_keycloak_update_role" {
  source = "./tdr-terraform-modules/iam_role"
  assume_role_policy = templatefile("${path.module}/templates/iam_role/github_assume_role.json.tpl", {
    account_id = data.aws_caller_identity.current.account_id,
    repo_names = jsonencode(concat(module.global_parameters.github_tdr_active_repositories, module.global_parameters.github_da_active_repositories))
  })
  common_tags = local.common_tags
  name        = "TDRGitHubRunKeycloakUpdateRole${title(local.environment)}"
  policy_attachments = {
    update_ecs_policy = module.github_run_keycloak_update_policy.policy_arn
  }
}

module "keycloak_update_cloudwatch" {
  source      = "./tdr-terraform-modules/cloudwatch_logs"
  common_tags = local.common_tags
  name        = "/ecs/keycloak-update-${local.environment}"
}

module "run_update_keycloak_execution_policy" {
  source = "./tdr-terraform-modules/iam_policy"
  name   = "TDRKeycloakUpdateECSExecutionPolicy${title(local.environment)}"
  policy_string = templatefile("${path.module}/templates/iam_policy/keycloak_update_execution_policy.json.tpl", {
    log_group_arn             = module.keycloak_update_cloudwatch.log_group_arn,
    management_account_number = data.aws_ssm_parameter.mgmt_account_number.value,
    aws_guardduty_ecr_arn     = local.aws_guardduty_ecr_arn
  })
}

module "run_update_keycloak_execution_role" {
  source             = "./tdr-terraform-modules/iam_role"
  assume_role_policy = templatefile("./templates/iam_policy/ecs_assume_role_policy.json.tpl", {})
  common_tags        = local.common_tags
  name               = "TDRKeycloakUpdateECSExecutionRole${title(local.environment)}"
  policy_attachments = {
    run_updates = module.run_update_keycloak_execution_policy.policy_arn,
    ssm         = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
  }
}

module "run_keycloak_update_ecs" {
  source       = "./tdr-terraform-modules/generic_ecs"
  cluster_name = "keycloak_update_${local.environment}"
  common_tags  = local.common_tags
  container_definition = templatefile("${path.module}/templates/ecs_tasks/keycloak_update.json.tpl", {
    project                    = var.project
    log_group_name             = "/ecs/keycloak-update-${local.environment}",
    app_environment            = local.environment
    management_account         = data.aws_ssm_parameter.mgmt_account_number.value
    client_secret_path         = local.keycloak_tdr_client_secret_name
    read_client_secret_path    = local.keycloak_tdr_read_client_secret_name
    backend_checks_secret_path = local.keycloak_backend_checks_secret_name
    realm_admin_secret_path    = local.keycloak_realm_admin_client_secret_name
    keycloak_properties_path   = local.keycloak_configuration_properties_name
    user_admin_path            = local.keycloak_user_admin_client_secret_name
    reporting_secret_path      = local.keycloak_reporting_client_secret_name
    github_secret_path         = data.aws_ssm_parameter.workflow_pat.name
  })
  container_name   = "${var.project}-keycloak-update"
  cpu              = 1024
  environment      = local.environment
  execution_role   = module.run_update_keycloak_execution_role.role.arn
  memory           = 2048
  private_subnets  = module.shared_vpc.private_subnets
  security_groups  = [module.keycloak_ecs_security_group.security_group_id]
  task_family_name = "keycloak-update-${local.environment}"
  task_role        = null
}
