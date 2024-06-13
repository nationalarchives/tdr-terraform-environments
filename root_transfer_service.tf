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
  cname_record_name     = "transfer-service"
  a_record_name         = "transfer-service"
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
    { port = 443, cidr_blocks = ["0.0.0.0/0"], description = "Allow all IPs over HTTPS" }
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
      app_image       = "${local.ecr_account_number}.dkr.ecr.eu-west-2.amazonaws.com/transfer-service:${local.environment}"
      log_group_name  = module.transfer_service_cloudwatch[0].log_group_name,
      app_environment = local.environment,
      aws_region      = local.region
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
  task_family_name             = "transfer_service-${local.environment}"
  task_role                    = module.transfer_service_task_role[0].role_arn
}
