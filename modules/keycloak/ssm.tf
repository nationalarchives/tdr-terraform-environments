resource "random_password" "keycloak_password" {
  length  = 16
  special = false
}

resource "random_uuid" "client_secret" {}
resource "random_uuid" "backend_checks_client_secret" {}

resource "aws_ssm_parameter" "database_url" {
  name  = "/${var.environment}/keycloak/database/url"
  type  = "SecureString"
  value = aws_rds_cluster.keycloak_database.endpoint
}

resource "aws_ssm_parameter" "database_username" {
  name  = "/${var.environment}/keycloak/database/username"
  type  = "SecureString"
  value = aws_rds_cluster.keycloak_database.master_username
}

resource "aws_ssm_parameter" "database_password" {
  name  = "/${var.environment}/keycloak/database/password"
  type  = "SecureString"
  value = aws_rds_cluster.keycloak_database.master_password
}

resource "aws_ssm_parameter" "keycloak_admin_password" {
  name  = "/${var.environment}/keycloak/admin/password"
  type  = "SecureString"
  value = random_password.password.result
}

resource "aws_ssm_parameter" "keycloak_admin_user" {
  name  = "/${var.environment}/keycloak/admin/user"
  type  = "SecureString"
  value = "tdr-keycloak-admin-${var.environment}"
}

resource "aws_ssm_parameter" "keycloak_client_secret" {
  name  = "/${var.environment}/keycloak/client/secret"
  type  = "SecureString"
  value = random_uuid.client_secret.result

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "keycloak_backend_checks_client_secret" {
  name  = "/${var.environment}/keycloak/backend_checks_client/secret"
  type  = "SecureString"
  value = random_uuid.backend_checks_client_secret.result

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "keycloak_realm_admin_client_secret" {
  name  = "/${var.environment}/keycloak/realm_admin_client/secret"
  type  = "SecureString"
  value = random_uuid.backend_checks_client_secret.result

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "keycloak_configuration_properties" {
  name  = "/${var.environment}/keycloak/configuration_properties"
  type  = "String"
  value = "${var.environment}_properties.json"
}

resource "aws_ssm_parameter" "keycloak_user_admin_client_secret" {
  name  = "/${var.environment}/keycloak/user_admin_client/secret"
  type  = "SecureString"
  value = random_uuid.backend_checks_client_secret.result

  lifecycle {
    ignore_changes = [value]
  }
}

//No programmatical method to retrieve value from GoUk Notify service
//Use Terraform to add the parameter and update value manually
//As added by Terraform won't be removed when Terraform apply run
resource "aws_ssm_parameter" "keycloak_govuk_notify_api_key" {
  name  = "/${var.environment}/keycloak/govuk_notify/api_key"
  type  = "SecureString"
  value = "to_be_manually_added"

  lifecycle {
    ignore_changes = [value]
  }
}

//No programmatical method to retrieve value from GoUk Notify service
//Use Terraform to add the parameter and update value manually
//As added by Terraform won't be removed when Terraform apply run
resource "aws_ssm_parameter" "keycloak_govuk_notify_template_id" {
  name  = "/${var.environment}/keycloak/govuk_notify/template_id"
  type  = "SecureString"
  value = "to_be_manually_added"

  lifecycle {
    ignore_changes = [value]
  }
}
