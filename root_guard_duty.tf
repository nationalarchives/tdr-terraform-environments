locals {
  malware_scan_bucket_enabled = [
    module.upload_file_cloudfront_dirty_s3,
    module.draft_metadata_bucket
  ]
}

resource "aws_guardduty_malware_protection_plan" "guard_duty_s3_malware_scan" {
  for_each = { for bucket in local.malware_scan_bucket_enabled : bucket.s3_bucket_id => bucket.s3_bucket_id }
  role     = module.aws_guard_duty_s3_malware_scan_role.role_arn

  protected_resource {
    s3_bucket {
      bucket_name = each.value
    }
  }

  actions {
    tagging {
      status = "ENABLED"
    }
  }

  tags = local.common_tags
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
    enabled_bucket_arns        = [for bucket in local.malware_scan_bucket_enabled : bucket.s3_bucket_arn]
    enabled_bucket_object_arns = [for bucket in local.malware_scan_bucket_enabled : "${bucket.s3_bucket_arn}/*"]
    malware_validation_objects = [for bucket in local.malware_scan_bucket_enabled :
      "arn:aws:s3:::${bucket.s3_bucket_name}/malware-protection-resource-validation-object"
    ]
  })
}

module "aws_guard_duty_s3_malware_scan_threat_found_event" {
  source = "./da-terraform-modules/cloudwatch_events"
  event_pattern = templatefile("${path.module}/templates/guard_duty/guard_duty_s3_malware_scan_pattern.json.tpl", {
    bucket_names = [for bucket in local.malware_scan_bucket_enabled : bucket.s3_bucket_name]
  })
  sns_topic_event_target_arn = module.notifications_topic.sns_arn
  rule_name                  = "guard-duty-s3-malware-threat-found"
  rule_description           = "Notify threat found Guard Duty S3 malware scan"
}
