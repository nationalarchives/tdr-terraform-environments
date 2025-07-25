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
      "Action": [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:sqs:eu-west-2:${account_id}:${sqs_queue}"
    },
    {
      "Action": "kms:Decrypt",
      "Effect": "Allow",
      "Resource": "${kms_key_id}"
    },
    {
      "Effect": "Allow",
      "Action": [
         "s3:GetObject",
         "s3:GetObjectTagging",
         "s3:ListBucket",
         "s3:PutObject",
         "s3:PutObjectTagging"
       ],
       "Resource": [
         "arn:aws:s3:::${export_bucket}",
         "arn:aws:s3:::${export_bucket}/*",
         "arn:aws:s3:::${judgment_export_bucket}",
         "arn:aws:s3:::${judgment_export_bucket}/*"
       ]
    }
  ]
}
