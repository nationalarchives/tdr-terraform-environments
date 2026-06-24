{
  "Statement": [
    {
      "Sid": "KMSs3DraftMetadataBucketPermission",
      "Action": [
        "kms:Decrypt",
        "kms:GenerateDataKey"
      ],
      "Effect": "Allow",
      "Resource": ${kms_bucket_key_arns}
    },
    {
      "Action": [
        "S3:GetObject",
        "s3:GetObjectTagging",
        "s3:PutObject",
        "s3:PutObjectTagging"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::tdr-draft-metadata-${environment}/*",
        "arn:aws:s3:::tdr-draft-metadata-${environment}"
      ]
    },
    {
      "Sid": "S3TransferErrorsBucketPermission",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectTagging",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::tdr-transfer-errors-${environment}",
        "arn:aws:s3:::tdr-transfer-errors-${environment}/*"
      ]
    }
  ],
  "Version": "2012-10-17"
}
