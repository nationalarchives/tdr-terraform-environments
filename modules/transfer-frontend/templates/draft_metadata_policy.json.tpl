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
    }
  ],
  "Version": "2012-10-17"
}
