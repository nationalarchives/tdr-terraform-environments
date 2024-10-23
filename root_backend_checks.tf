module "backend_checks_api_policy" {
  source        = "./tdr-terraform-modules/iam_policy"
  name          = "TDRBackendChecksAPIPolicy${title(local.environment)}"
  policy_string = templatefile("./templates/iam_policy/api_gateway_state_machine_policy.json.tpl", { account_id = data.aws_caller_identity.current.account_id, state_machine_arn = module.backend_checks_step_function.state_machine_arn })
}

module "backend_checks_api_role" {
  source             = "./tdr-terraform-modules/iam_role"
  assume_role_policy = templatefile("./templates/iam_policy/assume_role_policy.json.tpl", { service = "apigateway.amazonaws.com" })
  common_tags        = local.common_tags
  name               = "TDRBackendChecksAPIRole${title(local.environment)}"
  policy_attachments = {
    AmazonAPIGatewayPushToCloudWatchLogs = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs",
    AWSStepFunctionsFullAccess           = "arn:aws:iam::aws:policy/AWSStepFunctionsFullAccess"
  }
}

module "backend_checks_api" {
  source = "./tdr-terraform-modules/apigateway"
  api_definition = templatefile("./templates/api_gateway/backend_checks.json.tpl", {
    environment       = local.environment
    title             = "Backend Checks API"
    role_arn          = module.backend_checks_api_role.role.arn
    region            = local.region
    lambda_arn        = module.export_authoriser_lambda.export_api_authoriser_arn
    state_machine_arn = "arn:aws:states:${local.region}:${data.aws_caller_identity.current.account_id}:stateMachine:TDRBackendChecks${title(local.environment)}"

  })
  api_name    = "BackendChecks"
  common_tags = local.common_tags
  environment = local.environment
}

module "outbound_with_db_security_group" {
  source      = "./tdr-terraform-modules/security_group"
  description = "Outbound access on 443 and access to the database security group"
  name        = "outbound_with_db_security_group"
  vpc_id      = module.shared_vpc.vpc_id
  common_tags = local.common_tags
  egress_cidr_rules = [
    { port = 443, cidr_blocks = ["0.0.0.0/0"], description = "Allow outbound access on port 443", protocol = "-1" }
  ]
  egress_security_group_rules = [
    {
      port        = 5432, security_group_id = module.api_database_security_group.security_group_id,
      description = "Allow Postgres port from the backend checks", protocol = "-1"
    }
  ]
}

module "outbound_only_security_group" {
  source      = "./tdr-terraform-modules/security_group"
  description = "Outbound access on 443 only"
  name        = "outbound_only_security_group"
  vpc_id      = module.shared_vpc.vpc_id
  common_tags = local.common_tags
  egress_cidr_rules = [
    { port = 443, cidr_blocks = ["0.0.0.0/0"], description = "Allow outbound access on port 443", protocol = "tcp" }
  ]
}

module "file_upload_data" {
  source               = "./tdr-terraform-modules/generic_lambda"
  tags                 = local.common_tags
  function_name        = local.file_upload_data_function_name
  handler              = "lambda_handler.handler"
  reserved_concurrency = -1
  timeout_seconds      = 60
  policies = {
    "TDRFileUploadDataLambdaPolicy${title(local.environment)}" = templatefile("./templates/iam_policy/lambda_s3_policy.json.tpl", {
      function_name              = local.file_upload_data_function_name,
      bucket_name                = local.upload_files_cloudfront_dirty_bucket_name
      account_id                 = data.aws_caller_identity.current.account_id,
      parameter_name             = local.keycloak_backend_checks_secret_name
      backend_checks_bucket_name = module.backend_lambda_function_bucket.s3_bucket_name
      decryption_keys            = jsonencode([module.s3_upload_kms_key.kms_key_arn])
      encryption_keys            = jsonencode([module.s3_internal_kms_key.kms_key_arn])
    })
  }
  role_name = "TDRFileUploadDataLambdaRole${title(local.environment)}"
  runtime   = local.runtime_python_3_9
  plaintext_env_vars = {
    API_URL                    = "${module.consignment_api.api_url}/graphql"
    AUTH_URL                   = local.keycloak_auth_url
    CLIENT_ID                  = local.keycloak_backend-checks_client_id
    CLIENT_SECRET_PATH         = local.keycloak_backend_checks_secret_name
    BUCKET_NAME                = local.upload_files_cloudfront_dirty_bucket_name
    BACKEND_CHECKS_BUCKET_NAME = module.backend_lambda_function_bucket.s3_bucket_name
  }
  vpc_config = [
    {
      subnet_ids         = module.shared_vpc.private_subnets
      security_group_ids = [module.outbound_only_security_group.security_group_id]
    }
  ]
}

module "api_update_v2" {
  source               = "./tdr-terraform-modules/generic_lambda"
  tags                 = local.common_tags
  function_name        = local.api_update_v2_function_name
  handler              = "uk.gov.nationalarchives.api.update.Lambda::update"
  reserved_concurrency = -1
  timeout_seconds      = 600
  policies = {
    "TDRAPIUpdateV2LambdaPolicy${title(local.environment)}" = templatefile("./templates/iam_policy/lambda_policy.json.tpl", {
      function_name  = local.api_update_v2_function_name,
      account_id     = data.aws_caller_identity.current.account_id,
      parameter_name = local.keycloak_backend_checks_secret_name
      bucket_name    = module.backend_lambda_function_bucket.s3_bucket_name
    })
  }
  role_name = "TDRAPIUpdateV2LambdaRole${title(local.environment)}"
  runtime   = local.runtime_java_11
  plaintext_env_vars = {
    API_URL            = "${module.consignment_api.api_url}/graphql"
    AUTH_URL           = local.keycloak_auth_url
    CLIENT_ID          = local.keycloak_backend-checks_client_id
    CLIENT_SECRET_PATH = local.keycloak_backend_checks_secret_name
    S3_ENDPOINT        = local.s3_endpoint
  }
  vpc_config = [
    {
      subnet_ids         = module.shared_vpc.private_subnets
      security_group_ids = [module.outbound_only_security_group.security_group_id]
    }
  ]
}

module "file_format_v2" {
  source               = "./tdr-terraform-modules/generic_lambda"
  tags                 = local.common_tags
  function_name        = local.file_format_v2_function_name
  handler              = "uk.gov.nationalarchives.fileformat.Lambda::process"
  reserved_concurrency = -1
  timeout_seconds      = 60
  policies = {
    "TDRFileFormatV2LambdaPolicy${title(local.environment)}" = templatefile("./templates/iam_policy/lambda_s3_only_policy.json.tpl", {
      function_name   = local.file_format_v2_function_name,
      account_id      = data.aws_caller_identity.current.account_id,
      bucket_name     = local.upload_files_cloudfront_dirty_bucket_name
      decryption_keys = jsonencode([module.s3_upload_kms_key.kms_key_arn])
    })
  }
  role_name = "TDRFileFormatV2LambdaRole${title(local.environment)}"
  runtime   = local.runtime_java_11
  plaintext_env_vars = {
    S3_BUCKET = local.upload_files_cloudfront_dirty_bucket_name
  }
  vpc_config = [
    {
      subnet_ids         = module.shared_vpc.private_subnets
      security_group_ids = [module.outbound_only_security_group.security_group_id]
    }
  ]
}

module "checksum_v2" {
  source               = "./tdr-terraform-modules/generic_lambda"
  tags                 = local.common_tags
  function_name        = local.checksum_v2_function_name
  handler              = "uk.gov.nationalarchives.checksum.Lambda::process"
  reserved_concurrency = -1
  timeout_seconds      = 300
  storage_size         = 2560
  policies = {
    "TDRChecksumV2LambdaPolicy${title(local.environment)}" = templatefile("./templates/iam_policy/lambda_s3_only_policy.json.tpl", {
      function_name   = local.checksum_v2_function_name,
      account_id      = data.aws_caller_identity.current.account_id,
      bucket_name     = local.upload_files_cloudfront_dirty_bucket_name
      decryption_keys = jsonencode([module.s3_upload_kms_key.kms_key_arn])
    })
  }
  role_name = "TDRChecksumV2LambdaRole${title(local.environment)}"
  runtime   = local.runtime_java_11
  plaintext_env_vars = {
    CHUNK_SIZE_IN_MB = 50
    S3_BUCKET        = local.upload_files_cloudfront_dirty_bucket_name
  }
  vpc_config = [
    {
      subnet_ids         = module.shared_vpc.private_subnets
      security_group_ids = [module.outbound_only_security_group.security_group_id]
    }
  ]
}

module "redacted_files" {
  source               = "./tdr-terraform-modules/generic_lambda"
  tags                 = local.common_tags
  function_name        = local.redacted_files_function_name
  handler              = "uk.gov.nationalarchives.Lambda::run"
  reserved_concurrency = -1
  policies = {
    "TDRRedactedFilesLambda${title(local.environment)}" = templatefile("./templates/iam_policy/lambda_s3_backend_checks_policy.json.tpl", {
      function_name = local.redacted_files_function_name
      bucket_name   = module.backend_lambda_function_bucket.s3_bucket_name
      account_id    = data.aws_caller_identity.current.account_id
    })
  }
  role_name = "TDRRedactedFilesLambdaRole${title(local.environment)}"
  runtime   = local.runtime_java_11
  vpc_config = [
    {
      subnet_ids         = module.shared_vpc.private_subnets
      security_group_ids = [module.outbound_only_security_group.security_group_id]
    }
  ]
  plaintext_env_vars = {
    S3_ENDPOINT = local.s3_endpoint
  }
}

module "statuses" {
  source               = "./tdr-terraform-modules/generic_lambda"
  tags                 = local.common_tags
  function_name        = local.statuses_function_name
  handler              = "uk.gov.nationalarchives.Lambda::run"
  reserved_concurrency = -1
  timeout_seconds      = 30
  policies = {
    "TDRStatusesLambdaPolicy${title(local.environment)}" = templatefile("./templates/iam_policy/allow_iam_db_auth.json.tpl", {
      function_name  = local.statuses_function_name,
      account_id     = data.aws_caller_identity.current.account_id,
      resource_id    = module.consignment_api_database.resource_id
      user_name      = local.consignment_user_name
      bucket_name    = module.backend_lambda_function_bucket.s3_bucket_name
      parameter_name = local.url_path
    })
  }
  role_name = "TDRStatusesLambdaRole${title(local.environment)}"
  runtime   = local.runtime_java_11
  plaintext_env_vars = {
    USER_NAME    = local.consignment_user_name
    URL_PATH     = local.url_path
    USE_IAM_AUTH = true
    S3_ENDPOINT  = local.s3_endpoint
  }
  vpc_config = [
    {
      subnet_ids         = module.shared_vpc.private_subnets
      security_group_ids = [module.outbound_with_db_security_group.security_group_id]
    }
  ]
}

module "yara_av_v2" {
  source               = "./tdr-terraform-modules/generic_lambda"
  tags                 = local.common_tags
  function_name        = local.yara_av_v2_function_name
  handler              = "matcher.matcher_lambda_handler"
  reserved_concurrency = -1
  timeout_seconds      = 300
  storage_size         = 2560
  policies = {
    "TDRYaraAVV2LambdaPolicy${title(local.environment)}" = templatefile("./templates/iam_policy/lambda_av_policy.json.tpl", {
      function_name     = local.yara_av_v2_function_name,
      account_id        = data.aws_caller_identity.current.account_id,
      dirty_bucket      = local.upload_files_cloudfront_dirty_bucket_name
      clean_bucket      = module.upload_bucket.s3_bucket_name
      quarantine_bucket = module.upload_bucket_quarantine.s3_bucket_name
      metadata_bucket   = local.draft_metadata_s3_bucket_name
      decryption_keys   = jsonencode([module.s3_upload_kms_key.kms_key_arn])
      encryption_keys   = jsonencode([module.s3_internal_kms_key.kms_key_arn])
    })
  }
  role_name = "TDRYaraAVV2LambdaRole${title(local.environment)}"
  runtime   = local.runtime_python_3_9
  plaintext_env_vars = {
    ENVIRONMENT    = local.environment
    ROOT_DIRECTORY = local.tmp_directory
  }
  vpc_config = [
    {
      subnet_ids         = module.shared_vpc.private_subnets
      security_group_ids = [module.outbound_only_security_group.security_group_id]
    }
  ]
}

module "backend_checks_results" {
  source               = "./tdr-terraform-modules/generic_lambda"
  tags                 = local.common_tags
  function_name        = local.backend_checks_results_function_name
  handler              = "lambda_handler.lambda_handler"
  reserved_concurrency = -1
  policies = {
    "TDRBackendChecksResultsLambdaPolicy${title(local.environment)}" = templatefile("./templates/iam_policy/lambda_s3_backend_checks_policy.json.tpl", {
      function_name = local.backend_checks_results_function_name,
      account_id    = data.aws_caller_identity.current.account_id,
      bucket_name   = module.backend_lambda_function_bucket.s3_bucket_name
    })
  }
  role_name = "TDRBackendChecksResultsLambdaRole${title(local.environment)}"
  runtime   = local.runtime_python_3_9
  plaintext_env_vars = {
    ENVIRONMENT    = local.environment
    ROOT_DIRECTORY = local.tmp_directory
  }
  vpc_config = [
    {
      subnet_ids         = module.shared_vpc.private_subnets
      security_group_ids = [module.outbound_only_security_group.security_group_id]
    }
  ]
}

module "backend_checks_step_function" {
  source             = "./tdr-terraform-modules/stepfunctions"
  tags               = local.common_tags
  project            = var.project
  step_function_name = "BackendChecks"
  definition = templatefile("./templates/step_function/backend_checks_definition.json.tpl", {
    environment                 = local.environment
    backend_checks_results_arn  = module.backend_checks_results.lambda_arn
    file_upload_data_lambda_arn = module.file_upload_data.lambda_arn
    api_update_v2_lambda_arn    = module.api_update_v2.lambda_arn
    yara_av_v2_lambda_arn       = module.yara_av_v2.lambda_arn
    statuses_lambda_arn         = module.statuses.lambda_arn
    file_format_v2_lambda_arn   = module.file_format_v2.lambda_arn
    checksum_v2_lambda_arn      = module.checksum_v2.lambda_arn
    redacted_files_lambda_arn   = module.redacted_files.lambda_arn
    notification_lambda_arn     = module.notification_lambda.ecr_scan_notification_lambda_arn[0]
  })
  environment = local.environment
  policy = templatefile("./templates/iam_policy/backend_check_policy.json.tpl", {
    file_upload_data_lambda_arn = module.file_upload_data.lambda_arn
    backend_checks_results_arn  = module.backend_checks_results.lambda_arn
    statuses_lambda_arn         = module.statuses.lambda_arn
    yara_av_v2_lambda_arn       = module.yara_av_v2.lambda_arn
    file_format_v2_lambda_arn   = module.file_format_v2.lambda_arn
    checksum_v2_lambda_arn      = module.checksum_v2.lambda_arn
    redacted_files_lambda_arn   = module.redacted_files.lambda_arn
    api_update_v2_lambda_arn    = module.api_update_v2.lambda_arn
    notification_lambda_arn     = module.notification_lambda.ecr_scan_notification_lambda_arn[0],
    backend_checks_bucket_arn   = module.backend_lambda_function_bucket.s3_bucket_arn
    state_machine_arn           = module.backend_checks_step_function.state_machine_arn
  })
}
