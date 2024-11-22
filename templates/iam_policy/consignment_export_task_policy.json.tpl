{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "states:SendTaskFailure",
        "states:SendTaskHeartbeat",
        "states:SendTaskSuccess"
      ],
      "Resource": [
        "arn:aws:states:${aws_region}:${account}:stateMachine:TDRConsignmentExport${titleEnvironment}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "elasticfilesystem:ClientWrite"
      ],
      "Resource": "*"
    },
    {
      "Action": "rds-db:connect",
      "Effect": "Allow",
      "Resource": [
        "arn:aws:rds-db:${aws_region}:${account}:dbuser:${instance_resource_id}/consignment_api_user"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectTagging",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::tdr-upload-files-${environment}/*",
        "arn:aws:s3:::tdr-upload-files-${environment}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": "sns:Publish",
      "Resource": "arn:aws:sns:${aws_region}:${account}:${topic_name}"
    },
    {
      "Sid": "KMSs3ExportBucketPermission",
      "Action": [
        "kms:Decrypt",
        "kms:GenerateDataKey"
      ],
      "Effect": "Allow",
      "Resource": ${kms_bucket_key_arns}
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:PutObjectTagging"
      ],
      "Resource": [
        "arn:aws:s3:::tdr-consignment-export-${environment}/*",
        "arn:aws:s3:::tdr-consignment-export-${environment}",
        "arn:aws:s3:::tdr-consignment-export-judgment-${environment}/*",
        "arn:aws:s3:::tdr-consignment-export-judgment-${environment}",
        "arn:aws:s3:::${export_bucket_name}/*",
        "arn:aws:s3:::${export_bucket_name}",
        "arn:aws:s3:::${judgment_export_bucket_name}/*",
        "arn:aws:s3:::${judgment_export_bucket_name}"
      ]
    }
  ]
}

