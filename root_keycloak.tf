module "keycloak_cloudwatch" {
  source      = "./tdr-terraform-modules/cloudwatch_logs"
  common_tags = local.common_tags
  name        = "/ecs/keycloak-auth-${local.environment}"
}

module "keycloak_ecs_execution_policy" {
  source = "./tdr-terraform-modules/iam_policy"
  name   = "KeycloakECSExecutionPolicy${title(local.environment)}"
  policy_string = templatefile("${path.module}/templates/iam_policy/keycloak_ecs_execution_policy.json.tpl", {
    cloudwatch_log_group  = module.keycloak_cloudwatch.log_group_arn,
    ecr_account_number    = local.ecr_account_number,
    aws_guardduty_ecr_arn = local.aws_guardduty_ecr_arn
  })
}

module "keycloak_ecs_task_policy" {
  source        = "./tdr-terraform-modules/iam_policy"
  name          = "KeycloakECSTaskPolicy${title(local.environment)}"
  policy_string = templatefile("${path.module}/templates/iam_policy/keycloak_ecs_task_role_policy.json.tpl", { account_id = data.aws_caller_identity.current.account_id, environment = local.environment, kms_arn = module.encryption_key.kms_key_arn, instance_resource_id = module.keycloak_database_instance.resource_id, govuk_notify_api_key_path = local.keycloak_govuk_notify_api_key_name, govuk_notify_template_id_path = local.keycloak_govuk_notify_template_id_name })
}

module "keycloak_execution_role" {
  source             = "./tdr-terraform-modules/iam_role"
  assume_role_policy = templatefile("${path.module}/templates/iam_policy/ecs_assume_role_policy.json.tpl", {})
  common_tags        = local.common_tags
  name               = "KeycloakECSExecutionRole${title(local.environment)}"
  policy_attachments = {
    ssm_policy       = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess",
    execution_policy = module.keycloak_ecs_execution_policy.policy_arn
  }
}

module "keycloak_task_role" {
  source             = "./tdr-terraform-modules/iam_role"
  assume_role_policy = templatefile("${path.module}/templates/iam_policy/ecs_assume_role_policy.json.tpl", {})
  common_tags        = local.common_tags
  name               = "KeycloakECSTaskRole${title(local.environment)}"
  policy_attachments = { task_policy = module.keycloak_ecs_task_policy.policy_arn }
}

module "keycloak_ssm_parameters" {
  source      = "./tdr-terraform-modules/ssm_parameter"
  common_tags = local.common_tags
  random_parameters = [
    { name = local.keycloak_backend_checks_secret_name, description = "The Keycloak backend checks secret", value = random_uuid.backend_checks_client_secret.result, type = "SecureString" },
    { name = local.keycloak_tdr_client_secret_name, description = "The Keycloak tdr client secret", value = random_uuid.client_secret.result, type = "SecureString" },
    { name = local.keycloak_tdr_read_client_secret_name, description = "The Keycloak tdr-user-read client secret", value = random_uuid.client_secret.result, type = "SecureString" },
    { name = local.keycloak_tdr_transfer_service_secret_name, description = "The Keycloak tdr-transfer-service client secret", value = random_uuid.client_secret.result, type = "SecureString" },
    { name = local.keycloak_user_password_name, description = "The Keycloak user password", value = random_password.keycloak_password.result, type = "SecureString" },
    { name = local.keycloak_admin_password_name, description = "The Keycloak admin password", value = random_password.password.result, type = "SecureString" },
    { name = local.keycloak_govuk_notify_api_key_name, description = "The GovUK Notify API key", value = "to_be_manually_added", type = "SecureString", tier = "Advanced" },
    { name = local.keycloak_govuk_notify_template_id_name, description = "The GovUK Notify Template ID", value = "to_be_manually_added", type = "SecureString" },
    { name = local.keycloak_admin_user_name, description = "The Keycloak admin user", value = "tdr-keycloak-admin-${local.environment}", type = "SecureString" },
    { name = local.keycloak_configuration_properties_name, description = "The Keycloak configuration properties file ", value = "${local.environment}_properties.json", type = "SecureString" },
    { name = local.keycloak_user_admin_client_secret_name, description = "The Keycloak user admin secret", value = random_uuid.backend_checks_client_secret.result, type = "SecureString" },
    { name = local.keycloak_reporting_client_secret_name, description = "The Keycloak reporting client secret", value = random_uuid.reporting_client_secret.result, type = "SecureString" },
    { name = local.keycloak_realm_admin_client_secret_name, description = "The Keycloak realm admin secret", value = random_uuid.backend_checks_client_secret.result, type = "SecureString" },
    { name = local.slack_bot_token_name, description = "The Slack bot token", value = random_uuid.slack_bot_token.result, type = "SecureString" }
  ]
}

module "keycloak_ecs_security_group" {
  source      = "./tdr-terraform-modules/security_group"
  description = "Controls access within our network for the Keycloak ECS Task"
  name        = "tdr-keycloak-ecs-security-group-new"
  vpc_id      = module.shared_vpc.vpc_id
  common_tags = local.common_tags
  ingress_security_group_rules = [
    { port = 8080, security_group_id = module.keycloak_alb_security_group.security_group_id, description = "Allow the load balancer to access the task" },
    { port = 9000, security_group_id = module.keycloak_alb_security_group.security_group_id, description = "Allow the load balancer to access the task health endpoints" }
  ]
  egress_cidr_rules = [{ port = 0, cidr_blocks = ["0.0.0.0/0"], description = "Allow outbound access on all ports", protocol = "-1" }]
}

module "keycloak_alb_security_group" {
  source      = "./tdr-terraform-modules/security_group"
  description = "Controls access to the keycloak load balancer"
  name        = "keycloak-load-balancer-security-group-new"
  vpc_id      = module.shared_vpc.vpc_id
  common_tags = local.common_tags
  ingress_cidr_rules = [
    { port = 443, cidr_blocks = ["0.0.0.0/0"], description = "Allow all IPs over HTTPS" }
  ]
  egress_cidr_rules = [{ port = 0, cidr_blocks = ["0.0.0.0/0"], description = "Allow outbound access on all ports", protocol = "-1" }]
}

module "keycloak_database_security_group" {
  source      = "./tdr-terraform-modules/security_group"
  description = "Controls access to the keycloak database"
  name        = "keycloak-database-security-group-new-${local.environment}"
  vpc_id      = module.shared_vpc.vpc_id
  common_tags = local.common_tags
  ingress_security_group_rules = [
    { port = 5432, security_group_id = module.keycloak_ecs_security_group.security_group_id, description = "Allow Postgres port from the ECS task" },
    { port = 5432, security_group_id = module.create_keycloak_db_users_lambda_new.create_users_lambda_security_group_id[0], description = "Allow Postgres port from the create user lambda" }
  ]
  egress_security_group_rules = [{ port = 5432, security_group_id = module.keycloak_ecs_security_group.security_group_id, description = "Allow Postgres port from the ECS task", protocol = "-1" }]
}

module "tdr_keycloak_ecs" {
  source               = "./tdr-terraform-modules/generic_ecs"
  alb_target_group_arn = module.keycloak_tdr_alb.alb_target_group_arn
  cluster_name         = "keycloak_${local.environment}"
  common_tags          = local.common_tags
  container_definition = templatefile("${path.module}/templates/ecs_tasks/keycloak.json.tpl", {
    app_image                         = "${local.ecr_account_number}.dkr.ecr.eu-west-2.amazonaws.com/auth-server:${local.environment}"
    app_port                          = 8080
    app_environment                   = local.environment
    aws_region                        = local.region
    url_path                          = local.keycloak_db_url
    admin_user_path                   = local.keycloak_admin_user_name
    admin_password_path               = local.keycloak_admin_password_name
    client_secret_path                = local.keycloak_tdr_client_secret_name
    read_client_secret_path           = local.keycloak_tdr_read_client_secret_name
    backend_checks_client_secret_path = local.keycloak_backend_checks_secret_name
    realm_admin_client_secret_path    = local.keycloak_realm_admin_client_secret_name
    frontend_url                      = module.frontend.frontend_url
    configuration_properties_path     = local.keycloak_configuration_properties_name
    user_admin_client_secret_path     = local.keycloak_user_admin_client_secret_name
    govuk_notify_api_key_path         = local.keycloak_govuk_notify_api_key_name
    govuk_notify_template_id_path     = local.keycloak_govuk_notify_template_id_name
    reporting_client_secret_path      = local.keycloak_reporting_client_secret_name
    rotate_client_secrets_client_path = local.keycloak_rotate_secrets_client_secret_name
    sns_topic_arn                     = module.notifications_topic.sns_arn
    keycloak_host                     = "https://auth.${local.environment_domain}"
    block_shared_pages                = local.block_shared_keycloak_pages
  })
  container_name               = "keycloak"
  cpu                          = local.environment == "intg" ? 2048 : 1024
  environment                  = local.environment
  execution_role               = module.keycloak_execution_role.role.arn
  load_balancer_container_port = 8080
  memory                       = local.environment == "intg" ? 4096 : 3072
  private_subnets              = module.shared_vpc.private_backend_checks_subnets
  security_groups              = [module.keycloak_ecs_security_group.security_group_id]
  service_name                 = "keycloak_service_${local.environment}"
  task_family_name             = "keycloak-${local.environment}"
  task_role                    = module.keycloak_task_role.role.arn
}

module "keycloak_tdr_alb" {
  source                = "./tdr-terraform-modules/alb"
  project               = var.project
  function              = "keycloak-new"
  environment           = local.environment
  alb_log_bucket        = module.alb_logs_s3.s3_bucket_id
  alb_security_group_id = module.keycloak_alb_security_group.security_group_id
  alb_target_group_port = 8080
  health_check_port     = 9000
  alb_target_type       = "ip"
  certificate_arn       = module.keycloak_certificate.certificate_arn
  health_check_matcher  = "200,303"
  health_check_path     = "health"
  http_listener         = false
  public_subnets        = module.shared_vpc.public_subnets
  vpc_id                = module.shared_vpc.vpc_id
  common_tags           = local.common_tags
  own_host_header_only  = true
  host                  = "auth.${local.environment_domain}"
}

module "keycloak_database_instance" {
  source                  = "./tdr-terraform-modules/rds_instance"
  admin_username          = "keycloak_admin"
  availability_zone       = local.database_availability_zone
  common_tags             = local.common_tags
  database_name           = "keycloak"
  database_version        = "17.2"
  environment             = local.environment
  kms_key_id              = module.encryption_key.kms_key_arn
  private_subnets         = module.shared_vpc.private_subnets
  security_group_ids      = [module.keycloak_database_security_group.security_group_id]
  multi_az                = local.environment == "prod"
  ca_cert_identifier      = local.database_ca_cert_identifier
  backup_retention_period = local.rds_retention_period_days
  apply_immediately       = true
}

module "create_keycloak_db_users_lambda_new" {
  source                  = "./tdr-terraform-modules/lambda"
  project                 = var.project
  common_tags             = local.common_tags
  lambda_create_db_users  = true
  database_name           = "keycloak"
  lambda_name             = "create-keycloak-user"
  vpc_id                  = module.shared_vpc.vpc_id
  private_subnet_ids      = module.shared_vpc.private_subnets
  db_admin_user           = module.keycloak_database_instance.database_user
  db_admin_password       = module.keycloak_database_instance.database_password
  db_url                  = module.keycloak_database_instance.database_url
  kms_key_arn             = module.encryption_key.kms_key_arn
  keycloak_password       = module.keycloak_ssm_parameters.params[local.keycloak_user_password_name].value
  database_security_group = module.keycloak_database_security_group.security_group_id
}

module "keycloak_route53" {
  source                = "./tdr-terraform-modules/route53"
  common_tags           = local.common_tags
  environment_full_name = local.environment_full_name
  project               = "tdr"
  a_record_name         = "auth"
  alb_dns_name          = module.keycloak_tdr_alb.alb_dns_name
  alb_zone_id           = module.keycloak_tdr_alb.alb_zone_id
  create_hosted_zone    = false
  hosted_zone_id        = data.aws_route53_zone.tdr_dns_zone.id
}

module "keycloak_rotate_notify_api_key_event" {
  source                     = "./tdr-terraform-modules/cloudwatch_events"
  event_pattern              = "ssm_parameter_policy_action"
  sns_topic_event_target_arn = toset([module.notifications_topic.sns_arn])
  rule_name                  = "keycloak-rotate-notify-api-key"
  rule_description           = "Notify to rotate API Key"
  event_variables            = { parameter_name = local.keycloak_govuk_notify_api_key_name, policy_type = "NoChangeNotification" }
}
