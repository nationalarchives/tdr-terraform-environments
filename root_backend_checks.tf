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
  source                           = "./tdr-terraform-modules/generic_lambda"
  tags                             = local.common_tags
  function_name                    = local.file_upload_data_function_name
  handler                          = "lambda_handler.handler"
  reserved_concurrency             = -1
  timeout_seconds                  = 60
  cloudwatch_log_retention_in_days = module.global_parameters.policy_cloudwatch_logs_retention["${local.environment}"].lambda
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
  runtime   = local.runtime_python_3_13
  plaintext_env_vars = {
    API_URL                       = "${module.consignment_api.api_url}/graphql"
    AUTH_URL                      = local.keycloak_auth_url
    CLIENT_ID                     = local.keycloak_backend-checks_client_id
    CLIENT_SECRET_PATH            = local.keycloak_backend_checks_secret_name
    BUCKET_NAME                   = local.upload_files_cloudfront_dirty_bucket_name
    QUARANTINE_BUCKET_NAME        = local.upload_files_quarantine_bucket_name
    CLEAN_DESTINATION_BUCKET_NAME = local.upload_files_bucket_name
    BACKEND_CHECKS_BUCKET_NAME    = module.backend_lambda_function_bucket.s3_bucket_name
  }
  vpc_config = [
    {
      subnet_ids         = module.shared_vpc.private_backend_checks_subnets
      security_group_ids = [module.outbound_only_security_group.security_group_id]
    }
  ]
}

module "api_update_v2" {
  source                           = "./tdr-terraform-modules/generic_lambda"
  tags                             = local.common_tags
  function_name                    = local.api_update_v2_function_name
  handler                          = "uk.gov.nationalarchives.api.update.Lambda::update"
  reserved_concurrency             = -1
  timeout_seconds                  = 600
  cloudwatch_log_retention_in_days = module.global_parameters.policy_cloudwatch_logs_retention["${local.environment}"].lambda
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
      subnet_ids         = module.shared_vpc.private_backend_checks_subnets
      security_group_ids = [module.outbound_only_security_group.security_group_id]
    }
  ]
}



module "redacted_files" {
  source                           = "./tdr-terraform-modules/generic_lambda"
  tags                             = local.common_tags
  function_name                    = local.redacted_files_function_name
  handler                          = "uk.gov.nationalarchives.Lambda::run"
  reserved_concurrency             = -1
  timeout_seconds                  = 30
  cloudwatch_log_retention_in_days = module.global_parameters.policy_cloudwatch_logs_retention["${local.environment}"].lambda
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
      subnet_ids         = module.shared_vpc.private_backend_checks_subnets
      security_group_ids = [module.outbound_only_security_group.security_group_id]
    }
  ]
  plaintext_env_vars = {
    S3_ENDPOINT = local.s3_endpoint
  }
}

module "statuses" {
  source                           = "./tdr-terraform-modules/generic_lambda"
  tags                             = local.common_tags
  function_name                    = local.statuses_function_name
  handler                          = "uk.gov.nationalarchives.Lambda::run"
  reserved_concurrency             = -1
  timeout_seconds                  = contains(["staging", "prod"], local.environment) ? 600 : 30
  memory_size                      = contains(["staging", "prod"], local.environment) ? 4096 : 1024
  cloudwatch_log_retention_in_days = module.global_parameters.policy_cloudwatch_logs_retention["${local.environment}"].lambda
  policies = {
    "TDRStatusesLambdaPolicy${title(local.environment)}" = templatefile("./templates/iam_policy/lambda_statuses_policy.json.tpl", {
      function_name               = local.statuses_function_name,
      account_id                  = data.aws_caller_identity.current.account_id,
      bucket_name                 = module.backend_lambda_function_bucket.s3_bucket_name,
      client_secret_path          = local.keycloak_backend_checks_secret_name,
      sns_topic_arn               = module.notifications_topic.sns_arn,
      kms_key_arn                 = module.encryption_key.kms_key_arn,
      clean_bucket_name           = module.upload_bucket.s3_bucket_name,
      internal_s3_kms_key_arn     = module.s3_internal_kms_key.kms_key_arn,
      transfer_errors_bucket_name = module.tdr_transfer_errors_s3_bucket[0].s3_bucket_name,
    })
  }
  role_name = "TDRStatusesLambdaRole${title(local.environment)}"
  runtime   = local.runtime_java_11
  plaintext_env_vars = {
    API_URL            = "${module.consignment_api.api_url}/graphql"
    AUTH_URL           = local.keycloak_auth_url
    CLIENT_ID          = local.keycloak_backend-checks_client_id
    CLIENT_SECRET_PATH = local.keycloak_backend_checks_secret_name
    S3_ENDPOINT        = local.s3_endpoint
    SNS_TOPIC          = module.notifications_topic.sns_arn
    ENVIRONMENT        = local.environment
  }

  vpc_config = [
    {
      subnet_ids         = module.shared_vpc.private_backend_checks_subnets
      security_group_ids = [module.outbound_only_security_group.security_group_id]
    }
  ]
}

module "backend_checks_results" {
  source                           = "./tdr-terraform-modules/generic_lambda"
  tags                             = local.common_tags
  function_name                    = local.backend_checks_results_function_name
  handler                          = "lambda_handler.lambda_handler"
  reserved_concurrency             = -1
  timeout_seconds                  = 120
  cloudwatch_log_retention_in_days = module.global_parameters.policy_cloudwatch_logs_retention["${local.environment}"].lambda
  policies = {
    "TDRBackendChecksResultsLambdaPolicy${title(local.environment)}" = templatefile("./templates/iam_policy/lambda_s3_backend_checks_policy.json.tpl", {
      function_name = local.backend_checks_results_function_name,
      account_id    = data.aws_caller_identity.current.account_id,
      bucket_name   = module.backend_lambda_function_bucket.s3_bucket_name
    })
  }
  role_name = "TDRBackendChecksResultsLambdaRole${title(local.environment)}"
  runtime   = local.runtime_python_3_13
  plaintext_env_vars = {
    ENVIRONMENT    = local.environment
    ROOT_DIRECTORY = local.tmp_directory
  }
  vpc_config = [
    {
      subnet_ids         = module.shared_vpc.private_backend_checks_subnets
      security_group_ids = [module.outbound_only_security_group.security_group_id]
    }
  ]
}

module "file_checks" {
  source               = "./da-terraform-modules/lambda"
  tags                 = local.common_tags
  function_name        = local.file_checks_function_name
  handler              = "uk.gov.nationalarchives.filechecks.Lambda::process"
  reserved_concurrency = -1
  timeout_seconds      = 900
  storage_size         = 2560
  memory_size          = 3008
  policies = {
    "TDRFileChecksLambdaPolicy${title(local.environment)}" = templatefile("./templates/iam_policy/lambda_file_checks_policy.json.tpl", {
      function_name         = local.file_checks_function_name,
      account_id            = data.aws_caller_identity.current.account_id,
      dirty_bucket          = module.upload_file_cloudfront_dirty_s3.s3_bucket_name
      upload_bucket         = module.upload_bucket.s3_bucket_name
      quarantine_bucket     = module.upload_bucket_quarantine.s3_bucket_name
      draft_metadata_bucket = local.draft_metadata_s3_bucket_name
      s3_file_system_arn    = aws_s3files_file_system.file_checks_s3_files.arn
      decryption_keys       = jsonencode([module.s3_upload_kms_key.kms_key_arn])
      encryption_keys       = jsonencode([module.s3_internal_kms_key.kms_key_arn])
    })
  }
  runtime = local.runtime_java_21
  efs_access_points = [
    {
      access_point_arn = aws_s3files_access_point.file_checks_s3_files.arn
      mount_path       = "/mnt/s3"
    }
  ]
  vpc_config = {
    # The lambda can only attach the file system once the mount targets in its subnets exist
    subnet_ids         = values(aws_s3files_mount_target.file_checks_s3_files)[*].subnet_id
    security_group_ids = [module.outbound_only_security_group.security_group_id]
  }
}

resource "aws_iam_role" "s3files_file_checks" {
  name = "TDRFileChecksS3FilesRole${title(local.environment)}"
  assume_role_policy = templatefile("./templates/iam_policy/s3_files_assume_role_policy.json.tpl", {
    account_id = data.aws_caller_identity.current.account_id
  })
  tags = local.common_tags
}

resource "aws_iam_role_policy" "s3files_file_checks" {
  name = "TDRFileChecksS3FilesPolicy${title(local.environment)}"
  role = aws_iam_role.s3files_file_checks.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3BucketPermissions"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:ListBucketVersions"
        ]
        Resource = "arn:aws:s3:::${module.upload_file_cloudfront_dirty_s3.s3_bucket_name}"
        Condition = {
          StringEquals = {
            "aws:ResourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "S3ObjectPermissions"
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:DeleteObject*",
          "s3:GetObject*",
          "s3:List*",
          "s3:PutObject*"
        ]
        Resource = "arn:aws:s3:::${module.upload_file_cloudfront_dirty_s3.s3_bucket_name}/*"
        Condition = {
          StringEquals = {
            "aws:ResourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "UseKmsKeyWithS3Files"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:ReEncryptFrom",
          "kms:ReEncryptTo"
        ]
        Resource = module.s3_upload_kms_key.kms_key_arn
        Condition = {
          StringLike = {
            "kms:ViaService" = "s3.eu-west-2.amazonaws.com"
            "kms:EncryptionContext:aws:s3:arn" = [
              "arn:aws:s3:::${module.upload_file_cloudfront_dirty_s3.s3_bucket_name}",
              "arn:aws:s3:::${module.upload_file_cloudfront_dirty_s3.s3_bucket_name}/*"
            ]
          }
        }
      },
      {
        Sid    = "EventBridgeManage"
        Effect = "Allow"
        Action = [
          "events:DeleteRule",
          "events:DisableRule",
          "events:EnableRule",
          "events:PutRule",
          "events:PutTargets",
          "events:RemoveTargets"
        ]
        Resource = "arn:aws:events:*:*:rule/DO-NOT-DELETE-S3-Files*"
        Condition = {
          StringEquals = {
            "events:ManagedBy" = "elasticfilesystem.amazonaws.com"
          }
        }
      },
      {
        Sid    = "EventBridgeRead"
        Effect = "Allow"
        Action = [
          "events:DescribeRule",
          "events:ListRuleNamesByTarget",
          "events:ListRules",
          "events:ListTargetsByRule"
        ]
        Resource = "arn:aws:events:*:*:rule/*"
      }
    ]
  })
}

module "s3files_mount_target_security_group" {
  source      = "./tdr-terraform-modules/security_group"
  description = "S3 Files mount target NFS access for file-checks lambda"
  name        = "s3files_mount_target_security_group"
  vpc_id      = module.shared_vpc.vpc_id
  common_tags = local.common_tags
  ingress_security_group_rules = [
    {
      port              = 2049
      security_group_id = module.outbound_only_security_group.security_group_id
      description       = "Allow NFS from file-checks lambda security group"
    }
  ]
}

resource "aws_security_group_rule" "outbound_only_to_s3files_mount_target" {
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 2049
  to_port                  = 2049
  security_group_id        = module.outbound_only_security_group.security_group_id
  source_security_group_id = module.s3files_mount_target_security_group.security_group_id
  description              = "Allow NFS to the S3 Files mount targets"
}

resource "aws_s3files_file_system" "file_checks_s3_files" {
  bucket   = "arn:aws:s3:::${module.upload_file_cloudfront_dirty_s3.s3_bucket_name}"
  role_arn = aws_iam_role.s3files_file_checks.arn
  tags     = local.common_tags

  # S3 Files validates access to the bucket when the file system is created, so the role must already have its
  # permissions. Nothing else links the inline policy to this resource. The policy grants decrypt on the s3 upload KMS
  # key, so waiting for it also waits for that key policy to allow the role.
  depends_on = [aws_iam_role_policy.s3files_file_checks]
}

resource "aws_s3files_access_point" "file_checks_s3_files" {
  file_system_id = aws_s3files_file_system.file_checks_s3_files.id
  tags           = local.common_tags
}

resource "aws_s3files_mount_target" "file_checks_s3_files" {
  for_each       = toset(module.shared_vpc.private_backend_checks_subnets)
  file_system_id = aws_s3files_file_system.file_checks_s3_files.id
  subnet_id      = each.value
  security_groups = [
    module.s3files_mount_target_security_group.security_group_id,
    module.outbound_only_security_group.security_group_id
  ]
}

module "backend_checks_v2_step_function" {
  source             = "./tdr-terraform-modules/stepfunctions"
  tags               = local.common_tags
  project            = var.project
  step_function_name = "BackendChecksV2"
  definition = templatefile("./templates/step_function/backend_checks_v2_definition.json.tpl", {
    environment                    = local.environment
    backend_checks_results_arn     = module.backend_checks_results.lambda_arn
    file_checks_lambda_arn         = module.file_checks.lambda_arn
    file_upload_data_lambda_arn    = module.file_upload_data.lambda_arn
    api_update_v2_lambda_arn       = module.api_update_v2.lambda_arn
    statuses_lambda_arn            = module.statuses.lambda_arn
    redacted_files_lambda_arn      = module.redacted_files.lambda_arn
    notification_lambda_arn        = module.notification_lambda.ecr_scan_notification_lambda_arn[0]
    sns_topic                      = module.notifications_topic.sns_arn
    consignment_api_url            = module.consignment_api.api_url
    consignment_api_connection_arn = aws_cloudwatch_event_connection.consignment_api_connection.arn
  })
  environment = local.environment
  policy = templatefile("./templates/iam_policy/backend_check_v2_policy.json.tpl", {
    file_upload_data_lambda_arn = module.file_upload_data.lambda_arn
    backend_checks_results_arn  = module.backend_checks_results.lambda_arn
    statuses_lambda_arn         = module.statuses.lambda_arn
    file_checks_lambda_arn      = module.file_checks.lambda_arn
    redacted_files_lambda_arn   = module.redacted_files.lambda_arn
    api_update_v2_lambda_arn    = module.api_update_v2.lambda_arn
    notification_lambda_arn     = module.notification_lambda.ecr_scan_notification_lambda_arn[0],
    backend_checks_bucket_arn   = module.backend_lambda_function_bucket.s3_bucket_arn
    state_machine_arn           = module.backend_checks_v2_step_function.state_machine_arn
    sns_topic_arn               = module.notifications_topic.sns_arn
    kms_key_arn                 = module.encryption_key.kms_key_arn
    connection_arn              = aws_cloudwatch_event_connection.consignment_api_connection.arn
    consignment_api_url         = module.consignment_api.api_url
    account_id                  = data.aws_caller_identity.current.account_id
  })
}
