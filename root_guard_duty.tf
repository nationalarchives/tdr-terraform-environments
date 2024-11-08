# Note: currently cannot define the s3 malware scan rules as using an out of date AWS provider version.
# To implement the s3 malware scan rules do the following steps:
# 1. Run this Terraform
# 2. In the AWS console add the Guard Duty malware scan protection to the TDR dirty bucket
# 3. In the options to set up the malware scan, for the role, use the created role in this Terraform: TDRGuardDutyS3MalwareScanRole{environment}

locals {
  dirty_bucket_name = module.upload_file_cloudfront_dirty_s3.s3_bucket_name
}

module "aws_guard_duty_s3_malware_scan_role" {
  source = "./da-terraform-modules/iam_role"
  assume_role_policy = templatefile("./templates/iam_policy/guard_duty_s3_malware_scan_assume_role_policy.json.tpl", {
    account_id = data.aws_caller_identity.current.account_id
  })
  tags = local.common_tags
  name = "TDRGuardDutyS3MalwareScanRole${title(local.environment)}"
  policy_attachments = {
    policy = module.aws_guard_duty_s3_malware_scan_policy.policy_arn,
  }
}

module "aws_guard_duty_s3_malware_scan_policy" {
  source = "./da-terraform-modules/iam_policy"
  name   = "TDRGuardDutyS3MalwareScanPolicy${title(local.environment)}"
  tags   = local.common_tags
  policy_string = templatefile("./templates/iam_policy/guard_duty_s3_malware_scan_policy.json.tpl", {
    account_id                = data.aws_caller_identity.current.account_id,
    bucket_name               = local.dirty_bucket_name
    bucket_encryption_key_arn = module.s3_upload_kms_key.kms_key_arn
  })
}
