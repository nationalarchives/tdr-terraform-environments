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
        "arn:aws:logs:eu-west-2:${account_id}:log-group:*",
        "arn:aws:logs:eu-west-2:${account_id}:log-group:*:*"
      ]
    }
  ]
}
