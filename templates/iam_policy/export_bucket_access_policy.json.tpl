{
  "Statement": [
    {
      "Action": [
        "s3:Get*",
        "s3:List*",
        "s3:Describe*"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::tdr-consignment-export-${environment}/*",
        "arn:aws:s3:::tdr-consignment-export-${environment}",
        "arn:aws:s3:::tdr-consignment-export-judgment-${environment}/*",
        "arn:aws:s3:::tdr-consignment-export-judgment-${environment}"
      ],
      "Sid": "s3ExportBucketsReadAccess"
    },
    {
      "Action": [
        "kms:Decrypt",
        "kms:GenerateDataKey"
      ],
      "Effect": "Allow",
      "Resource": "${kms_export_bucket_key_arn}",
      "Sid": "KMSs3ExportBucketPermission"
    }
  ],
  "Version": "2012-10-17"
}