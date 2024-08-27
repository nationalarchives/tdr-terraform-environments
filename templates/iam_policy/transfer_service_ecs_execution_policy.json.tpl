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
            "arn:aws:ecr:eu-west-2:${management_account_number}:repository/transfer-service",
            "${aws_guardduty_ecr_arn}"
          ]
        },
        {
          "Sid": "",
          "Effect": "Allow",
          "Action": [
            "ecr:GetAuthorizationToken"
          ],
          "Resource" : "*"
        }
  ]
}
