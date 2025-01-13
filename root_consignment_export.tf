module "consignment_export_ecs_security_group" {
  source            = "./tdr-terraform-modules/security_group"
  description       = "Allow Consignment Export ECS task to mount EFS volume"
  name              = "consignment-export-allow-ecs-mount-efs"
  vpc_id            = module.shared_vpc.vpc_id
  common_tags       = local.common_tags
  egress_cidr_rules = [{ port = 0, cidr_blocks = ["0.0.0.0/0"], description = "Allow outbound access on all ports", protocol = "-1" }]
}

module "consignment_export_cloudwatch" {
  source      = "./tdr-terraform-modules/cloudwatch_logs"
  common_tags = local.common_tags
  name        = "/ecs/consignment-export-${local.environment}"
}

module "consignment_export_execution_role" {
  source             = "./tdr-terraform-modules/iam_role"
  assume_role_policy = templatefile("./templates/iam_policy/ecs_assume_role_policy.json.tpl", { account_id = data.aws_caller_identity.current.account_id })
  common_tags        = local.common_tags
  name               = "TDRConsignmentExportECSExecutionRole${title(local.environment)}"
  policy_attachments = {
    execution_policy = module.consignment_export_execution_policy.policy_arn,
    ssm_policy       = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
  }
}

module "consignment_export_task_role" {
  source             = "./tdr-terraform-modules/iam_role"
  assume_role_policy = templatefile("./templates/iam_policy/ecs_assume_role_policy.json.tpl", {})
  common_tags        = local.common_tags
  name               = "TDRConsignmentExportEcsTaskRole${title(local.environment)}"
  policy_attachments = {
    task_policy = module.consignment_export_task_policy.policy_arn
  }
}

module "consignment_export_execution_policy" {
  source = "./tdr-terraform-modules/iam_policy"
  name   = "TDRConsignmentExportECSExecutionPolicy${title(local.environment)}"
  policy_string = templatefile("./templates/iam_policy/consignment_export_execution_policy.json.tpl", {
    log_group_arn             = "${module.consignment_export_cloudwatch.log_group_arn}:*",
    file_system_arn           = module.export_efs.file_system_arn,
    management_account_number = data.aws_ssm_parameter.mgmt_account_number.value,
    aws_guardduty_ecr_arn     = local.aws_guardduty_ecr_arn,
    account_id = data.aws_caller_identity.current.account_id
    }
  )
}

module "consignment_export_task_policy" {
  source = "./tdr-terraform-modules/iam_policy"
  name   = "TDRConsignmentExportECSTaskPolicy${title(local.environment)}"
  policy_string = templatefile(
    "${path.module}/templates/iam_policy/consignment_export_task_policy.json.tpl", {
      account_id = data.aws_caller_identity.current.account_id
      environment          = local.environment,
      titleEnvironment     = title(local.environment),
      aws_region           = local.region,
      account              = data.aws_caller_identity.current.account_id,
      instance_resource_id = module.consignment_api_database.resource_id
      kms_bucket_key_arns = jsonencode([
        module.s3_external_kms_key.kms_key_arn,
        module.s3_internal_kms_key.kms_key_arn
      ])
      export_bucket_name          = local.flat_format_bucket_name
      judgment_export_bucket_name = local.flat_format_judgment_bucket_name
      topic_name                  = local.external_notifications_topic
  })
}

module "consignment_export_ecs_task" {
  source       = "./tdr-terraform-modules/generic_ecs"
  cluster_name = "consignment_export_${local.environment}"
  common_tags  = local.common_tags
  container_definition = templatefile(
    "${path.module}/templates/ecs_tasks/consignment_export.json.tpl", {
      log_group_name             = module.consignment_export_cloudwatch.log_group_name,
      app_environment            = local.environment,
      management_account         = data.aws_ssm_parameter.mgmt_account_number.value,
      backend_client_secret_path = module.keycloak_ssm_parameters.params[local.keycloak_backend_checks_secret_name].name
      clean_bucket               = module.upload_bucket.s3_bucket_name
      output_bucket              = module.export_bucket.s3_bucket_name
      output_bucket_judgment     = module.export_bucket_judgment.s3_bucket_name
      api_url                    = "${module.consignment_api.api_url}/graphql"
      output_topic_arn           = module.external_sns_notifications_topic.sns_arn
      auth_url                   = local.keycloak_auth_url
      region                     = local.region
      download_files_batch_size  = 40
      download_batch_delay_ms    = 10
  })
  container_name   = "consignmentexport"
  cpu              = 1024
  environment      = local.environment
  execution_role   = module.consignment_export_execution_role.role.arn
  memory           = 2048
  private_subnets  = module.shared_vpc.private_subnets
  security_groups  = [module.consignment_export_ecs_security_group.security_group_id]
  task_family_name = "consignment-export-${local.environment}"
  task_role        = module.consignment_export_task_role.role.arn
  file_systems     = [{ file_system_id = module.export_efs.file_system_id, access_point_id = module.export_efs.access_point.id }]
}
