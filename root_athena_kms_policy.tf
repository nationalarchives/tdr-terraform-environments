# This file adds KMS key policy statements to allow SSO Athena Analytics roles to access encrypted S3 buckets
# Wildcards are used because SSO role names have auto-generated suffixes

data "aws_iam_policy_document" "athena_sso_kms_statement" {
  count = local.environment == "prod" ? 1 : 0

  statement {
    sid    = "AthenaSSORoleKMSAccess"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:Encrypt",
      "kms:ReEncrypt*",
      "kms:DescribeKey"
    ]
    resources = ["*"]

    condition {
      test     = "ArnLike"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/*/AWSReservedSSO_TDR-Reporting_*"]
    }
  }
}

# Merge the athena SSO statement with the default KMS policy
data "aws_iam_policy_document" "s3_internal_kms_key_with_athena" {
  count = local.environment == "prod" ? 1 : 0

  source_policy_documents = [
    module.s3_internal_kms_key.kms_key_policy_json,
    data.aws_iam_policy_document.athena_sso_kms_statement[0].json
  ]
}

# Update the KMS key policy to include the athena SSO access
resource "aws_kms_key_policy" "s3_internal_kms_key_athena_policy" {
  count  = local.environment == "prod" ? 1 : 0
  key_id = module.s3_internal_kms_key.kms_key_id
  policy = data.aws_iam_policy_document.s3_internal_kms_key_with_athena[0].json
}

