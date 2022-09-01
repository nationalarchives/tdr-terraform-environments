{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "rds-db:connect",
      "Resource": [
        "arn:aws:rds-db:eu-west-2:${account_id}:dbuser:${resource_id}/consignment_api_user"
      ]
    }
  ]
}

