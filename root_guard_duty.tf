# Note: currently cannot define the s3 malware scan rules as using an out of date AWS provider version.
# To implement the s3 malware scan rules do the following steps:
# 1. Run this Terraform
# 2. In the AWS console add the Guard Duty malware scan protection to the TDR dirty buckets
# 3. In the options to set up the malware scan, for the role, use the created role in this Terraform: TDRGuardDutyS3MalwareScanRole{environment}

locals {
  malware_scan_bucket_enabled_names = [
    module.upload_file_cloudfront_dirty_s3.s3_bucket_name,
    module.draft_metadata_bucket.s3_bucket_name
  ]
  scan_complete_tag_key            = "GuardDutyMalwareScanStatus"
  scan_complete_threat_found_value = "THREATS_FOUND"
  scan_complete_threat_clear_value = "NO_THREATS_FOUND"
  threat_found_result              = "awsGuardDutyThreatFound"
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
    account_id                 = data.aws_caller_identity.current.account_id,
    bucket_encryption_key_arns = [module.s3_upload_kms_key.kms_key_arn, module.s3_internal_kms_key.kms_key_arn]
    enabled_bucket_arns        = [for bucket_name in local.malware_scan_bucket_enabled_names : "arn:aws:s3:::${bucket_name}"]
    enabled_bucket_object_arns = [for bucket_name in local.malware_scan_bucket_enabled_names : "arn:aws:s3:::${bucket_name}/*"]
    malware_validation_objects = [for bucket_name in local.malware_scan_bucket_enabled_names :
      "arn:aws:s3:::${bucket_name}/malware-protection-resource-validation-object"
    ]
  })
}

module "aws_guard_duty_s3_malware_scan_threat_found_event" {
  source = "./da-terraform-modules/cloudwatch_events"
  event_pattern = templatefile("${path.module}/templates/guard_duty/guard_duty_s3_malware_scan_pattern.json.tpl", {
    bucket_names       = local.malware_scan_bucket_enabled_names
    scan_result_status = local.scan_complete_threat_found_value
  })
  sns_topic_event_target_arn = module.notifications_topic.sns_arn
  rule_name                  = "guard-duty-s3-malware-threat-found"
  rule_description           = "Notify threat found Guard Duty S3 malware scan"
}
