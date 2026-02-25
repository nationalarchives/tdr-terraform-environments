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
        "s3:ListBucket",
        "s3:PutObjectTagging",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::${dirty_upload_bucket_name}",
        "arn:aws:s3:::${dirty_upload_bucket_name}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::${draft_metadata_bucket_name}",
        "arn:aws:s3:::${draft_metadata_bucket_name}/*",
        "arn:aws:s3:::${transfer_error_bucket_name}",
        "arn:aws:s3:::${transfer_error_bucket_name}/*"
      ]
    },
    {
      "Action": [
        "ssm:GetParameter"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:ssm:eu-west-2:${account_id}:parameter${auth_client_secret_path}",
        "arn:aws:ssm:eu-west-2:${account_id}:parameter${read_client_secret_path}"
        ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ],
      "Resource": "arn:aws:sqs:eu-west-2:${account_id}:${sqs_queue_name}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "states:StartExecution"
      ],
      "Resource": [
        "${backend_checks_arn}",
        "${metadata_checks_arn}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "sns:Publish"
      ],
      "Resource": "${notifications_topic_arn}"
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
