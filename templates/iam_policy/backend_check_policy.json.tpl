{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "lambda:InvokeFunction"
      ],
      "Resource": [
        "${api_update_v2_lambda_arn}",
        "${backend_checks_results_arn}",
        "${checksum_v2_lambda_arn}",
        "${file_format_v2_lambda_arn}",
        "${file_upload_data_lambda_arn}",
        "${notification_lambda_arn}",
        "${redacted_files_lambda_arn}",
        "${statuses_lambda_arn}",
        "${yara_av_v2_lambda_arn}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectTagging",
        "s3:ListBucket",
        "s3:PutObject",
        "s3:PutObjectTagging",
        "states:StartExecution"
      ],
      "Resource": [
        "${backend_checks_bucket_arn}/*",
        "${backend_checks_bucket_arn}",
        "${state_machine_arn}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "xray:PutTraceSegments",
        "xray:PutTelemetryRecords",
        "xray:GetSamplingRules",
        "xray:GetSamplingTargets"
      ],
      "Resource": "*"
    }
  ]
}
