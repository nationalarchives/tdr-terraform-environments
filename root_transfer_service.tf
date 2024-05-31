module "transfer_service_certificate" {
  source      = "./tdr-terraform-modules/certificatemanager"
  project     = var.project
  function    = "transfer-service"
  dns_zone    = local.environment_domain
  domain_name = "transfer-service.${local.environment_domain}"
  common_tags = local.common_tags
}

module "transfer_service_cloudwatch" {
  source      = "./tdr-terraform-modules/cloudwatch_logs"
  common_tags = local.common_tags
  name        = "/ecs/transfer-service-${local.environment}"
}

module "transfer_service_execution_role" {
  source             = "./da-terraform-modules/iam_role"
  assume_role_policy = templatefile("./templates/iam_policy/ecs_assume_role_policy.json.tpl", {})
  tags               = local.common_tags
  name               = "TDRTransferServiceECSExecutionRole${title(local.environment)}"
  policy_attachments = {
    execution_policy = module.transfer_service_execution_policy.policy_arn,
    ssm_policy       = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
  }
}

module "transfer_service_task_role" {
  source             = "./da-terraform-modules/iam_role"
  assume_role_policy = templatefile("./templates/iam_policy/ecs_assume_role_policy.json.tpl", {})
  tags               = local.common_tags
  name               = "TDRTransferServiceECSTaskRole${title(local.environment)}"
  policy_attachments = {
    task_policy = module.transfer_service_task_policy.policy_arn
  }
}

module "transfer_service_execution_policy" {
  source        = "./da-terraform-modules/iam_policy"
  name          = "TDRTransferServiceECSExecutionPolicy${title(local.environment)}"
  policy_string = templatefile("./templates/iam_policy/transfer_service_ecs_execution_policy.json.tpl", { log_group_arn = "${module.transfer_service_cloudwatch.log_group_arn}:*", management_account_number = data.aws_ssm_parameter.mgmt_account_number.value })
}

module "transfer_service_task_policy" {
  source = "./da-terraform-modules/iam_policy"
  name   = "TDRTransferServiceECSTaskPolicy${title(local.environment)}"
  policy_string = templatefile(
  "${path.module}/templates/iam_policy/transfer_service_ecs_task_policy.json.tpl", {})
}

module "transfer_service_ecs_security_group" {
  source      = "./tdr-terraform-modules/security_group"
  description = "Controls access within TDR network for the Transfer Service ECS Task"
  name        = "tdr-transfer-service-ecs-security-group"
  vpc_id      = module.shared_vpc.vpc_id
  common_tags = local.common_tags
  ingress_security_group_rules = [
    { port = 8080, security_group_id = module.keycloak_alb_security_group.security_group_id, description = "Allow the load balancer to access the task" }
  ]
  egress_cidr_rules = [{ port = 0, cidr_blocks = ["0.0.0.0/0"], description = "Allow outbound access on all ports", protocol = "-1" }]
}

module "transfer_service_alb_security_group" {
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
  source               = "./tdr-terraform-modules/generic_ecs"
  alb_target_group_arn = module.keycloak_tdr_alb.alb_target_group_arn
  cluster_name         = "transfer_service_${local.environment}"
  common_tags          = local.common_tags
  container_definition = templatefile(
    "${path.module}/templates/ecs_tasks/transfer_service.json.tpl", {
      app_image       = "${local.ecr_account_number}.dkr.ecr.eu-west-2.amazonaws.com/transfer-service:${local.environment}"
      log_group_name  = module.transfer_service_cloudwatch.log_group_name,
      app_environment = local.environment,
      aws_region      = local.region
  })
  container_name               = "transferservice"
  cpu                          = 512
  environment                  = local.environment
  execution_role               = module.transfer_service_execution_role.role_arn
  load_balancer_container_port = 8080
  memory                       = 1024
  private_subnets              = module.shared_vpc.private_backend_checks_subnets
  security_groups              = [module.transfer_service_ecs_security_group.security_group_id]
  service_name                 = "transfer_service_${local.environment}"
  task_family_name             = "transfer_service-${local.environment}"
  task_role                    = module.transfer_service_task_role.role_arn
}
