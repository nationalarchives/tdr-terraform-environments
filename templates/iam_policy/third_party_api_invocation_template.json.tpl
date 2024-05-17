{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "states:InvokeHTTPEndpoint",
      "Resource": "${step_function_arn}",
      "Condition": {
        "StringEquals": {
          "states:HTTPMethod": "POST"
        },
        "StringLike": {
          "states:HTTPEndpoint": "${api_url}/*"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": "events:RetrieveConnectionCredentials",
      "Resource": "${connection_arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:aws:secretsmanager:${region}:${account_number}:secret:events!connection/*"
    }
  ]
}
