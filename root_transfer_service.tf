locals {
  // Apply to intg environment only initially
  transfer_service_count = local.environment == "intg" ? 1 : 0
  ip_allow_list          = local.environment == "intg" ? local.ip_allowlist : ["0.0.0.0/0"]
  domain                 = "nationalarchives.gov.uk"
  sub_domain             = "transfer-service"
  hosted_zone_name       = local.environment_full_name == "production" ? "${local.sub_domain}.tdr.${local.domain}" : "${local.sub_domain}.tdr-${local.environment_full_name}.${local.domain}"
}

module "transfer_service_ssm_parameters" {
  source = "./da-terraform-modules/ssm_parameter"
  tags   = local.common_tags
  parameters = [
    {
      name        = local.keycloak_transfer_service_secret_name,
      description = "Secret for the transfer service client"
      type        = "SecureString"
      value       = "To be manually added"
    }
  ]
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
  policy_string = templatefile("./templates/iam_policy/transfer_service_ecs_execution_policy.json.tpl", { management_account_number = data.aws_ssm_parameter.mgmt_account_number.value, cloudwatch_log_group = module.transfer_service_cloudwatch[0].log_group_arn })
}

module "transfer_service_task_policy" {
  count  = local.transfer_service_count
  source = "./da-terraform-modules/iam_policy"
  name   = "TDRTransferServiceECSTaskPolicy${title(local.environment)}"
  tags   = local.common_tags
  policy_string = templatefile(
  "${path.module}/templates/iam_policy/transfer_service_ecs_task_policy.json.tpl", { account_id = data.aws_caller_identity.current.account_id, environment = local.environment })
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
  count                 = local.transfer_service_count
  source                = "./tdr-terraform-modules/route53"
  common_tags           = local.common_tags
  environment_full_name = local.environment_full_name
  project               = "tdr"
  a_record_name         = local.sub_domain
  alb_dns_name          = module.transfer_service_tdr_alb[0].alb_dns_name
  alb_zone_id           = module.transfer_service_tdr_alb[0].alb_zone_id
  create_hosted_zone    = false
  hosted_zone_id        = data.aws_route53_zone.tdr_dns_zone.id
}

module "transfer_service_tdr_alb" {
  count                 = local.transfer_service_count
  source                = "./tdr-terraform-modules/alb"
  project               = var.project
  function              = "transfer-service"
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
  cluster_name         = "transfer_service_${local.environment}"
  common_tags          = local.common_tags
  container_definition = templatefile(
    "${path.module}/templates/ecs_tasks/transfer_service.json.tpl", {
      app_image                 = "${local.ecr_account_number}.dkr.ecr.eu-west-2.amazonaws.com/transfer-service:${local.environment}"
      log_group_name            = module.transfer_service_cloudwatch[0].log_group_name,
      app_environment           = local.environment,
      aws_region                = local.region,
      records_upload_bucket     = module.upload_file_cloudfront_dirty_s3.s3_bucket_arn
      metadata_upload_bucket    = module.draft_metadata_bucket.s3_bucket_arn
      auth_url                  = local.keycloak_auth_url
      consignment_api_url       = module.consignment_api.api_url
      transfer_service_api_port = "8080"
  })
  container_name               = "transfer-service"
  cpu                          = 512
  environment                  = local.environment
  execution_role               = module.transfer_service_execution_role[0].role_arn
  load_balancer_container_port = 8080
  memory                       = 1024
  private_subnets              = module.shared_vpc.private_backend_checks_subnets
  security_groups              = [module.transfer_service_ecs_security_group[0].security_group_id]
  service_name                 = "transfer_service_${local.environment}"
  task_family_name             = "transfer_service_${local.environment}"
  task_role                    = module.transfer_service_task_role[0].role_arn
}

data "aws_ssm_parameter" "transfer_service_keycloak_secret" {
  name            = local.keycloak_transfer_service_secret_name
  with_decryption = true
}

resource "aws_cloudwatch_event_connection" "transfer_service_api_connection" {
  name               = "TDRTransferServiceAPIConnection${title(local.environment)}"
  authorization_type = "OAUTH_CLIENT_CREDENTIALS"

  auth_parameters {
    oauth {
      client_parameters {
        client_id     = local.keycloak_transfer_service_secret_name
        client_secret = data.aws_ssm_parameter.transfer_service_keycloak_secret.value
      }

      authorization_endpoint = "${local.keycloak_auth_url}/realms/tdr/protocol/openid-connect/token"
      http_method            = "POST"

      oauth_http_parameters {
        body {
          key             = "grant_type"
          value           = "client_credentials"
          is_value_secret = false
        }
      }
    }
  }
}

resource "aws_iam_policy" "transfer_service_data_load_policy" {
  name        = "TDRDataLoadPolicy${title(local.environment)}"
  description = "Policy to allow necessary lambda executions from step function"

  policy = templatefile("./templates/iam_policy/invoke_lambda_policy.json.tpl", {
    resources = jsonencode([
      module.yara_av_v2.lambda_arn,
      module.draft_metadata_validator_lambda.lambda_arn
    ])
  })
}

resource "aws_iam_policy" "transfer_service_api_invoke_policy" {
  name = "TDRTransferServiceAPIInvokePolicy${title(local.environment)}"

  policy = templatefile("./templates/iam_policy/third_party_api_invocation_template.json.tpl", {
    region            = local.region
    account_number    = var.tdr_account_number
    connection_arn    = aws_cloudwatch_event_connection.transfer_service_api_connection.arn
    api_url           = "https://${local.hosted_zone_name}"
    step_function_arn = module.transfer_service_data_load_sfn.step_function_arn
  })
}

module "transfer_service_data_load_sfn" {
  source             = "./da-terraform-modules/sfn"
  step_function_name = "TDRDataLoad${title(local.environment)}"
  step_function_definition = templatefile("./templates/step_function/data_load_definition.json.tpl", {
    antivirus_lambda_arn = module.yara_av_v2.lambda_arn
  })
  step_function_role_policy_attachments = {
    "lambda-policy" : aws_iam_policy.transfer_service_api_invoke_policy.arn,
    "api-invoke-policy" : aws_iam_policy.transfer_service_api_invoke_policy.arn
  }
}
