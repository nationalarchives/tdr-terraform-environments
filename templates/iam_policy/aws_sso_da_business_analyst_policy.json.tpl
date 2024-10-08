{
  "Statement": [
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
      "Sid": "ReadS3ExportBucketsPermission",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::tdr-consignment-export-${environment}/*",
        "arn:aws:s3:::tdr-consignment-export-${environment}",
        "arn:aws:s3:::tdr-export-${environment}/*",
        "arn:aws:s3:::tdr-export-${environment}"
      ]
    }
  ],
  "Version": "2012-10-17"
}
