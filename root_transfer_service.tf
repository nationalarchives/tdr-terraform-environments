locals {
  // Apply to intg environment only initially
  transfer_service_count = local.environment == "intg" ? 1 : 0
}

module "transfer_service_execution_role" {
  count              = local.transfer_service_count
  source             = "./da-terraform-modules/iam_role"
  assume_role_policy = templatefile("./templates/iam_policy/ecs_assume_role_policy.json.tpl", {})
  tags               = local.common_tags
  name               = "TDRTransferServiceECSExecutionRole${title(local.environment)}"
  policy_attachments = {
    execution_policy = module.transfer_service_execution_policy[0].policy_arn,
    ssm_policy       = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
  }
}

module "transfer_service_task_role" {
  count              = local.transfer_service_count
  source             = "./da-terraform-modules/iam_role"
  assume_role_policy = templatefile("./templates/iam_policy/ecs_assume_role_policy.json.tpl", {})
  tags               = local.common_tags
  name               = "TDRTransferServiceECSTaskRole${title(local.environment)}"
  policy_attachments = {
    task_policy = module.transfer_service_task_policy[0].policy_arn
  }
}

module "transfer_service_execution_policy" {
  count         = local.transfer_service_count
  source        = "./da-terraform-modules/iam_policy"
  name          = "TDRTransferServiceECSExecutionPolicy${title(local.environment)}"
  tags          = local.common_tags
  policy_string = templatefile("./templates/iam_policy/transfer_service_ecs_execution_policy.json.tpl", { management_account_number = data.aws_ssm_parameter.mgmt_account_number.value })
}

module "transfer_service_task_policy" {
  count  = local.transfer_service_count
  source = "./da-terraform-modules/iam_policy"
  name   = "TDRTransferServiceECSTaskPolicy${title(local.environment)}"
  tags   = local.common_tags
  policy_string = templatefile(
  "${path.module}/templates/iam_policy/transfer_service_ecs_task_policy.json.tpl", { account_id = data.aws_caller_identity.current.account_id, environment = local.environment })
}
