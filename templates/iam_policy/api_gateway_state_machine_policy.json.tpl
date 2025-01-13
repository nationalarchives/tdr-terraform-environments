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
        "states:StartExecution"
      ],
      "Resource": [
        "${state_machine_arn}"
      ],
      "Condition": {
        "StringEquals": {
          "AWS:SourceAccount": "${account_id}"
        }
      }
    }
  ]
}
