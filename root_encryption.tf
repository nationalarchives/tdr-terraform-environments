locals {
  e2e_testing_role_arns = local.environment == "prod" ? [] : [module.tdr_configuration.terraform_config[local.environment]["e2e_testing_role_arn"]]
  e2e_testing_role_arn  = local.environment == "prod" ? "" : module.tdr_configuration.terraform_config[local.environment]["e2e_testing_role_arn"]
  s3_external_service_details = [{
    service_name : "cloudwatch"
    service_source_account : data.aws_caller_identity.current.account_id
  }]
  wiz_role_arns                    = module.tdr_configuration.terraform_config[local.environment]["wiz_role_arns"]
  aws_back_up_roles                = local.environment == "prod" ? [local.aws_back_up_local_role] : []
  aggregate_processing_access_role = local.environment == "prod" ? [] : [module.aggregate_processing_lambda[0].lambda_role_arn]
}

module "s3_external_kms_key" {
  source   = "./da-terraform-modules/kms"
  key_name = "tdr-s3-external-kms-${local.environment}"
  tags     = local.common_tags
  default_policy_variables = {
    user_roles = concat([
      module.notification_lambda.notifications_lambda_role_arn[0],
      module.consignment_export_task_role.role.arn,
      local.dr2_copy_files_role,
    ], local.aws_sso_export_bucket_access_roles, local.standard_export_bucket_read_access_roles, local.judgment_export_bucket_read_access_roles)
    ci_roles                            = [local.assume_role]
    service_details                     = local.s3_external_service_details
    user_roles_decoupled                = concat(local.wiz_role_arns, local.aws_back_up_roles)
    persistent_resource_roles_decoupled = local.wiz_role_arns
  }
}

module "sns_external_kms_key" {
  source   = "./da-terraform-modules/kms"
  key_name = "tdr-sns-external-kms-${local.environment}"
  tags     = local.common_tags
  default_policy_variables = {
    user_roles = [module.consignment_export_task_role.role.arn]
    ci_roles   = [local.assume_role]
    service_details = [
      {
        service_name : "sns"
        service_source_account : data.aws_caller_identity.current.account_id
      }
    ]
    wiz_roles = local.wiz_role_arns
  }
}

module "s3_internal_kms_key" {
  source   = "./da-terraform-modules/kms"
  key_name = "tdr-s3-internal-kms-${local.environment}"
  tags     = local.common_tags
  default_policy_variables = {
    user_roles = concat([
      module.yara_av_v2.lambda_role_arn,
      module.file_upload_data.lambda_role_arn,
      module.consignment_export_task_role.role.arn,
      module.draft_metadata_persistence_lambda.lambda_role_arn,
      module.draft_metadata_checks_lambda.lambda_role_arn,
      module.frontend.task_role_arn,
      module.draft_metadata_checks.step_function_role_arn,
      module.aws_guard_duty_s3_malware_scan_role.role_arn
    ], local.aws_sso_internal_bucket_access_roles, local.e2e_testing_role_arns, local.aggregate_processing_access_role)
    ci_roles = [local.assume_role]
    service_details = [
      {
        service_name : "cloudwatch"
        service_source_account : data.aws_caller_identity.current.account_id
      }
    ]
    user_roles_decoupled                = concat(local.wiz_role_arns, local.aws_back_up_roles)
    persistent_resource_roles_decoupled = local.wiz_role_arns
  }
}

module "s3_upload_kms_key" {
  source   = "./da-terraform-modules/kms"
  key_name = "tdr-s3-upload-kms-${local.environment}"
  tags     = local.common_tags
  default_policy_variables = {
    user_roles = concat([
      module.yara_av_v2.lambda_role_arn,
      module.file_upload_data.lambda_role_arn,
      module.file_format_v2.lambda_role_arn,
      module.checksum_v2.lambda_role_arn,
      module.aws_guard_duty_s3_malware_scan_role.role_arn
    ], local.aws_sso_internal_bucket_access_roles, local.aws_back_up_roles, local.aggregate_processing_access_role, local.e2e_testing_role_arns)
    ci_roles = [local.assume_role]
    service_details = [
      {
        service_name : "cloudwatch"
        service_source_account : data.aws_caller_identity.current.account_id
      }
    ]
    cloudfront_distributions = [module.cloudfront_upload.cloudfront_arn]
    wiz_roles                = local.wiz_role_arns
  }
}
