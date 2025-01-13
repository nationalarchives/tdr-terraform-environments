{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "${cloudwatch_log_group}",
        "${cloudwatch_log_group}:log-stream:*",
        "arn:aws:ecr:eu-west-2:${ecr_account_number}:repository/auth-server",
        "${aws_guardduty_ecr_arn}"
      ],
      "Condition": {
        "StringEquals": {
          "AWS:SourceAccount": "${account_id}"
        }
      }
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken"
      ],
      "Resource" : "*",
      "Condition": {
        "StringEquals": {
          "AWS:SourceAccount": "${account_id}"
        }
      }
    }
  ]
}
