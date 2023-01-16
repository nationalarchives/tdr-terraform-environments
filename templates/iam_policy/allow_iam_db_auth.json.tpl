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
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "rds-db:connect",
      "Resource": [
        "arn:aws:rds-db:eu-west-2:${account_id}:dbuser:${resource_id}/${user_name}"
      ]
    }
  ]
}

