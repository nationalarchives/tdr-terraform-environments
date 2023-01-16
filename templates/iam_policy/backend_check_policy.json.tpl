{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "lambda:InvokeFunction"
      ],
      "Resource": [
        "${file_format_v2_arn}",
        "${yara_av_v2_arn}",
        "${checksum_v2_arn}",
        "${notification_arn}",
        "${file_upload_data_arn}",
        "${redacted_files_arn}",
        "${api_update_v2_arn}",
        "${statuses_arn}"
      ]
    }
  ]
}
