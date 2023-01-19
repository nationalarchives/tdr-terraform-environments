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
        "${checksum_v2_lambda_arn}",
        "${file_format_v2_lambda_arn}",
        "${file_upload_data_lambda_arn}",
        "${notification_lambda_arn}",
        "${redacted_files_lambda_arn}",
        "${statuses_lambda_arn}",
        "${yara_av_v2_lambda_arn}"
      ]
    }
  ]
}
