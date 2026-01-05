{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sqs:SendMessage"
      ],
      "Resource": [
        "arn:aws:sqs:eu-west-2:${account_id}:tdr-aggregate-processing-${environment}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectTagging"
      ],
      "Resource": [
        "arn:aws:s3:::${tdr_transfer_errors_s3_bucket_name}",
        "arn:aws:s3:::${tdr_transfer_errors_s3_bucket_name}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:GenerateDataKey"
      ],
      "Resource": "${kms_arn}"
    }
  ]
}
