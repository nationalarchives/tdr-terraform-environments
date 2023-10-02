{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:Get*",
        "s3:List*",
        "s3:Describe*"
      ],
      "Resource": [
        "arn:aws:s3:::tdr-consignment-export-intg/*",
        "arn:aws:s3:::tdr-consignment-export-intg",
        "arn:aws:s3:::tdr-consignment-export-judgment-intg/*",
        "arn:aws:s3:::tdr-consignment-export-judgment-intg"
      ],
      "Sid": "s3ExportBucketsReadOnlyPermission"
    },
    {
      "Action": [
        "kms:Decrypt",
        "kms:GenerateDataKey*"
      ],
      "Effect": "Allow",
      "Resource": "${export_bucket_kms_key_arn}",
      "Sid": "KMSs3ExportBucketPermission"
    }
  ]
}