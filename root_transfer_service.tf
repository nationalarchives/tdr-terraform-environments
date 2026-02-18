locals {
  // Apply to intg /staging environments only initially
  transfer_service_count = local.environment == "prod" ? 0 : 1
  ip_allow_list          = ["0.0.0.0/0"]
  domain                 = "nationalarchives.gov.uk"
  sub_domain             = "transfer-service"
  # Require abbreviated name for staging as ALB name cannot be more than 32 characters which is the case for staging
  alb_function_name                        = local.environment == "staging" ? "transfer-serv" : "transfer-service"
  aggregate_processing_function_name       = "tdr-aggregate-processing-${local.environment}"
  aggregate_processing_lambda_timeout_secs = 900

  transfer_service_ecs_task_role_arn = local.environment == "prod" ? "" : module.transfer_service_task_role[0].role_arn
  tdr_transfer_errors_s3_bucket_name = "tdr-transfer-errors-${local.environment}"
  block_api_documentation            = local.environment == "intg" || local.environment == "dev" ? false : true
  block_service_endpoints            = local.environment == "prod" ? true : false
  block_tdr_custom_tags              = local.environment == "prod" ? true : false
}

module "transfer_service_execution_role" {
  count  = local.transfer_service_count
  source = "./da-terraform-modules/iam_role"
  assume_role_policy = templatefile("./templates/iam_policy/ecs_assume_role_policy.json.tpl", {
    account_id = data.aws_caller_identity.current.account_id
  })
  tags = local.common_tags
  name = "TDRTransferServiceECSExecutionRole${title(local.environment)}"
  policy_attachments = {
    execution_policy = module.transfer_service_execution_policy[0].policy_arn,
    ssm_policy       = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
  }
}

module "transfer_service_task_role" {
  count  = local.transfer_service_count
  source = "./da-terraform-modules/iam_role"
  assume_role_policy = templatefile("./templates/iam_policy/ecs_assume_role_policy.json.tpl", {
    account_id = data.aws_caller_identity.current.account_id
  })
  tags = local.common_tags
  name = "TDRTransferServiceECSTaskRole${title(local.environment)}"
  policy_attachments = {
    task_policy = module.transfer_service_task_policy[0].policy_arn
  }
}

module "transfer_service_execution_policy" {
  count  = local.transfer_service_count
  source = "./da-terraform-modules/iam_policy"
  name   = "TDRTransferServiceECSExecutionPolicy${title(local.environment)}"
  tags   = local.common_tags
  policy_string = templatefile("./templates/iam_policy/transfer_service_ecs_execution_policy.json.tpl", {
    management_account_number = data.aws_ssm_parameter.mgmt_account_number.value,
    cloudwatch_log_group      = module.transfer_service_cloudwatch[0].log_group_arn,
    aws_guardduty_ecr_arn     = local.aws_guardduty_ecr_arn
  })
}

module "transfer_service_task_policy" {
  count  = local.transfer_service_count
  source = "./da-terraform-modules/iam_policy"
  name   = "TDRTransferServiceECSTaskPolicy${title(local.environment)}"
  tags   = local.common_tags
  policy_string = templatefile(
    "${path.module}/templates/iam_policy/transfer_service_ecs_task_policy.json.tpl", {
      account_id                         = data.aws_caller_identity.current.account_id, environment = local.environment,
      tdr_transfer_errors_s3_bucket_name = local.tdr_transfer_errors_s3_bucket_name,
      kms_arn                            = module.s3_internal_kms_key.kms_key_arn
  })
}

module "transfer_service_certificate" {
  count       = local.transfer_service_count
  source      = "./da-terraform-modules/certificatemanager"
  project     = var.project
  function    = "transfer-service"
  dns_zone    = local.environment_domain
  domain_name = "transfer-service.${local.environment_domain}"
  common_tags = local.common_tags
  environment = local.environment
}

module "transfer_service_route53" {
  count              = local.transfer_service_count
  source             = "./da-terraform-modules/route53"
  common_tags        = local.common_tags
  a_record_name      = "transfer-service"
  alb_dns_name       = module.transfer_service_tdr_alb[0].alb_dns_name
  alb_zone_id        = module.transfer_service_tdr_alb[0].alb_zone_id
  create_hosted_zone = false
  hosted_zone_name   = data.aws_route53_zone.tdr_dns_zone.name
  hosted_zone_id     = data.aws_route53_zone.tdr_dns_zone.id
}

module "transfer_service_tdr_alb" {
  count                 = local.transfer_service_count
  source                = "./tdr-terraform-modules/alb"
  project               = var.project
  function              = local.alb_function_name
  environment           = local.environment
  alb_log_bucket        = module.alb_logs_s3.s3_bucket_id
  alb_security_group_id = module.transfer_service_alb_security_group[0].security_group_id
  alb_target_group_port = 8080
  alb_target_type       = "ip"
  certificate_arn       = module.transfer_service_certificate[0].certificate_arn
  health_check_matcher  = "200,303"
  health_check_path     = "healthcheck"
  http_listener         = false
  public_subnets        = module.shared_vpc.public_subnets
  vpc_id                = module.shared_vpc.vpc_id
  common_tags           = local.common_tags
  own_host_header_only  = true
  host                  = "transfer-service.${local.environment_domain}"
}

module "transfer_service_cloudwatch" {
  count       = local.transfer_service_count
  source      = "./tdr-terraform-modules/cloudwatch_logs"
  common_tags = local.common_tags
  name        = "/ecs/transfer-service-${local.environment}"
}

module "transfer_service_ecs_security_group" {
  count       = local.transfer_service_count
  source      = "./tdr-terraform-modules/security_group"
  description = "Controls access within TDR network for the Transfer Service ECS Task"
  name        = "tdr-transfer-service-ecs-security-group"
  vpc_id      = module.shared_vpc.vpc_id
  common_tags = local.common_tags
  ingress_security_group_rules = [
    { port = 8080, security_group_id = module.transfer_service_alb_security_group[0].security_group_id, description = "Allow the load balancer to access the task" }
  ]
  egress_cidr_rules = [{ port = 0, cidr_blocks = ["0.0.0.0/0"], description = "Allow outbound access on all ports", protocol = "-1" }]
}

module "transfer_service_alb_security_group" {
  count       = local.transfer_service_count
  source      = "./tdr-terraform-modules/security_group"
  description = "Controls access to the Transfer Service load balancer"
  name        = "transfer-service-load-balancer-security-group"
  vpc_id      = module.shared_vpc.vpc_id
  common_tags = local.common_tags
  ingress_cidr_rules = [
    { port = 443, cidr_blocks = local.ip_allow_list, description = "Restrict IPs over HTTPS" }
  ]
  egress_cidr_rules = [{ port = 0, cidr_blocks = ["0.0.0.0/0"], description = "Allow outbound access on all ports", protocol = "-1" }]
}

module "transfer_service_ecs_task" {
  count                = local.transfer_service_count
  source               = "./tdr-terraform-modules/generic_ecs"
  alb_target_group_arn = module.transfer_service_tdr_alb[0].alb_target_group_arn
  cluster_name         = "transferservice_${local.environment}"
  common_tags          = local.common_tags
  container_definition = templatefile(
    "${path.module}/templates/ecs_tasks/transfer_service.json.tpl", {
      app_image                           = "${local.ecr_account_number}.dkr.ecr.eu-west-2.amazonaws.com/transfer-service:${local.environment}"
      log_group_name                      = module.transfer_service_cloudwatch[0].log_group_name,
      app_environment                     = local.environment,
      aws_region                          = local.region,
      records_upload_bucket_arn           = module.upload_file_cloudfront_dirty_s3.s3_bucket_arn
      records_upload_bucket_name          = module.upload_file_cloudfront_dirty_s3.s3_bucket_name
      metadata_upload_bucket_arn          = module.upload_file_cloudfront_dirty_s3.s3_bucket_arn
      metadata_upload_bucket_name         = module.upload_file_cloudfront_dirty_s3.s3_bucket_name
      transfer_error_bucket_name          = local.tdr_transfer_errors_s3_bucket_name
      auth_url                            = local.keycloak_auth_url
      consignment_api_url                 = module.consignment_api.api_url
      transfer_service_api_port           = "8080"
      max_number_records                  = 3000
      max_individual_file_size_mb         = 2000
      max_transfer_size_mb                = 5000
      transfer_service_client_secret_path = local.keycloak_tdr_transfer_service_secret_name
      throttle_amount                     = 50
      throttle_per_ms                     = 10
      user_email_sns_topic_arn            = module.notifications_topic.sns_arn
      user_read_client_secret             = local.keycloak_tdr_read_client_secret_name
      user_read_client_id                 = local.keycloak_user_read_client_id
      aggregate_processing_queue_url      = module.aggregate_processing_sqs_queue[0].sqs_queue_url
      s3_acl_header_value                 = module.s3_put_request_header_acl_ssm_parameter.params[local.s3_put_request_header_acl_parameter].value
      s3_if_none_match_header_value       = module.s3_put_request_header_if_none_match_ssm_parameter.params[local.s3_put_request_header_if_none_match_parameter].value
      block_api_documentation             = local.block_api_documentation
      block_service_endpoints             = local.block_service_endpoints
      block_tdr_custom_tags               = local.block_tdr_custom_tags
  })
  container_name               = "transfer-service"
  cpu                          = 512
  environment                  = local.environment
  execution_role               = module.transfer_service_execution_role[0].role_arn
  load_balancer_container_port = 8080
  memory                       = 1024
  private_subnets              = module.shared_vpc.private_backend_checks_subnets
  security_groups              = [module.transfer_service_ecs_security_group[0].security_group_id]
  service_name                 = "transferservice_service_${local.environment}"
  task_family_name             = "transfer_service_${local.environment}"
  task_role                    = module.transfer_service_task_role[0].role_arn
}

module "aggregate_processing_lambda" {
  count           = local.transfer_service_count
  source          = "./da-terraform-modules/lambda"
  function_name   = local.aggregate_processing_function_name
  tags            = local.common_tags
  handler         = "uk.gov.nationalarchives.aggregate.processing.AggregateProcessingLambda::handleRequest"
  timeout_seconds = local.aggregate_processing_lambda_timeout_secs
  memory_size     = 512
  runtime         = "java21"
  lambda_sqs_queue_mappings = [{
    sqs_queue_arn         = "arn:aws:sqs:eu-west-2:${var.tdr_account_number}:${local.aggregate_processing_function_name}",
    ignore_enabled_status = false
  }]
  policies = {
    "TDRAggregateProcessingLambdaPolicy${title(local.environment)}" = templatefile("./templates/iam_policy/aggregate_processing_lambda_policy.json.tpl", {
      function_name              = local.aggregate_processing_function_name
      account_id                 = var.tdr_account_number
      dirty_upload_bucket_name   = local.upload_files_cloudfront_dirty_bucket_name
      draft_metadata_bucket_name = local.draft_metadata_s3_bucket_name
      auth_client_secret_path    = local.keycloak_tdr_transfer_service_secret_name
      read_client_secret_path    = local.keycloak_tdr_read_client_secret_name
      sqs_queue_name             = local.aggregate_processing_function_name
      kms_arn                    = module.encryption_key.kms_key_arn
      backend_checks_arn         = module.backend_checks_step_function.state_machine_arn
      metadata_checks_arn        = module.draft_metadata_checks.step_function_arn
      notifications_topic_arn    = module.notifications_topic.sns_arn
    })
  }
  plaintext_env_vars = {
    ENVIRONMENT                     = local.environment
    GRAPHQL_API_URL                 = "${module.consignment_api.api_url}/graphql"
    AUTH_URL                        = local.keycloak_auth_url
    AUTH_CLIENT_SECRET_PATH         = local.keycloak_tdr_transfer_service_secret_name
    BACKEND_CHECKS_ARN              = module.backend_checks_step_function.state_machine_arn
    METADATA_CHECKS_ARN             = module.draft_metadata_checks.step_function_arn
    NOTIFICATIONS_TOPIC_ARN         = module.notifications_topic.sns_arn
    KEYCLOAK_READ_AUTH_SECRET_PATH  = local.keycloak_tdr_read_client_secret_name
    DRAFT_METADATA_BUCKET_NAME      = local.draft_metadata_s3_bucket_name
    TRANSFER_ERROR_BUCKET_NAME      = local.tdr_transfer_errors_s3_bucket_name
    MALWARE_SCAN_TAG_KEY            = local.scan_complete_tag_key
    MALWARE_SCAN_THREAT_FOUND_VALUE = local.scan_complete_threat_found_value
  }
  vpc_config = {
    subnet_ids         = module.shared_vpc.private_backend_checks_subnets
    security_group_ids = [module.outbound_only_security_group.security_group_id]
  }
}

module "aggregate_processing_sqs_queue" {
  count      = 1
  source     = "./da-terraform-modules/sqs"
  tags       = local.common_tags
  queue_name = local.aggregate_processing_function_name
  sqs_policy = templatefile("./templates/sqs/aggregate_processing_policy.json.tpl", {
    region         = local.region,
    environment    = local.environment,
    account_id     = data.aws_caller_identity.current.account_id,
    sqs_queue_name = local.aggregate_processing_function_name
  })
  encryption_type    = "kms"
  kms_key_id         = module.encryption_key.kms_alias_arn
  visibility_timeout = 6 * local.aggregate_processing_lambda_timeout_secs
}

module "tdr_transfer_errors_s3_bucket" {
  count       = 1
  source      = "./da-terraform-modules/s3"
  bucket_name = local.tdr_transfer_errors_s3_bucket_name
  common_tags = local.common_tags
  kms_key_arn = module.s3_internal_kms_key.kms_key_arn
}
