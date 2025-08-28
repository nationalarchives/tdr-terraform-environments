{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:logs:eu-west-2:${account_id}:log-group:/aws/lambda/${function_name}",
        "arn:aws:logs:eu-west-2:${account_id}:log-group:/aws/lambda/${function_name}:log-stream:*"
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
        "arn:aws:s3:::${dirty_upload_bucket_name}",
        "arn:aws:s3:::${dirty_upload_bucket_name}/*"
      ]
    },
    {
      "Action": [
        "ssm:GetParameter"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:ssm:eu-west-2:${account_id}:parameter${auth_client_secret_path}"
    }
  ]
}
