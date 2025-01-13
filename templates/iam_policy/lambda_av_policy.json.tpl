{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:eu-west-2:${account_id}:log-group:/aws/lambda/${function_name}",
        "arn:aws:logs:eu-west-2:${account_id}:log-group:/aws/lambda/${function_name}:log-stream:*"
      ],
      "Condition": {
        "StringEquals": {
          "AWS:SourceAccount": "${account_id}"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeNetworkInterfaces"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "AWS:SourceAccount": "${account_id}"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectTagging",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::${dirty_bucket}",
        "arn:aws:s3:::${dirty_bucket}/*"
      ],
      "Condition": {
        "StringEquals": {
          "AWS:SourceAccount": "${account_id}"
        }
      }
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
        "arn:aws:s3:::${clean_bucket}",
        "arn:aws:s3:::${clean_bucket}/*",
        "arn:aws:s3:::${quarantine_bucket}",
        "arn:aws:s3:::${quarantine_bucket}/*",
        "arn:aws:s3:::${metadata_bucket}",
        "arn:aws:s3:::${metadata_bucket}/*"
      ],
      "Condition": {
        "StringEquals": {
          "AWS:SourceAccount": "${account_id}"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": "kms:Decrypt",
      "Condition": {
        "StringEquals": {
          "AWS:SourceAccount": "${account_id}"
        }
      },
      "Resource": ${decryption_keys}
    },
    {
      "Effect": "Allow",
      "Action": "kms:Encrypt",
      "Condition": {
        "StringEquals": {
          "AWS:SourceAccount": "${account_id}"
        }
      },
      "Resource": ${encryption_keys}
    }
  ]
}
