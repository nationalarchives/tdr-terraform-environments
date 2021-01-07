resource "aws_iam_openid_connect_provider" "tdr_frontend_provider" {
  url             = "${var.auth_url}/realms/tdr"
  client_id_list  = ["tdr-fe"]
  thumbprint_list = [data.aws_ssm_parameter.auth_server_thumbprint.value]
}

resource "aws_cognito_identity_pool" "tdr_frontend_identity_pool" {
  identity_pool_name               = "TDR Frontend Identity ${title(var.environment)}"
  allow_unauthenticated_identities = false
  openid_connect_provider_arns     = [aws_iam_openid_connect_provider.tdr_frontend_provider.arn]
}

resource "aws_cognito_identity_pool_roles_attachment" "tdr_frontend_roles_attachment" {
  identity_pool_id = aws_cognito_identity_pool.tdr_frontend_identity_pool.id
  roles = {
    authenticated = aws_iam_role.cognito_authorised_role.arn
  }
}

resource "aws_iam_role_policy_attachment" "tdr_frontend_role_attachment" {
  policy_arn = aws_iam_policy.cognito_auth_policy.arn
  role       = aws_iam_role.cognito_authorised_role.name
}

data "template_file" "cognito_auth_role_template" {
  template = file("${path.module}/templates/cognito_authenticated.json.tpl")
  vars = {
    environment = var.environment
  }
}

data "template_file" "cognito_assume_role_policy" {
  template = file("${path.module}/templates/cognito_assume_role_policy.json.tpl")
  vars = {
    identity_pool_id = aws_cognito_identity_pool.tdr_frontend_identity_pool.id
  }
}

resource "aws_iam_policy" "cognito_auth_policy" {
  policy = data.template_file.cognito_auth_role_template.rendered
  name   = "CognitoAuthPolicy${title(var.environment)}"
}

resource "aws_iam_role" "cognito_authorised_role" {
  name               = "TDRCognitoAuthorisedRole${title(var.environment)}"
  description        = "Role for authenticated users for the ${title(var.environment)} environment"
  assume_role_policy = data.template_file.cognito_assume_role_policy.rendered
  max_session_duration = 12 * 60 * 60
  tags = merge(
    var.common_tags,
    map(
      "Name", "${title(var.environment)} Terraform Role",
    )
  )
}

data "aws_ssm_parameter" "auth_server_thumbprint" {
  name = "/${var.environment}/frontend/auth/thumbprint"
}


