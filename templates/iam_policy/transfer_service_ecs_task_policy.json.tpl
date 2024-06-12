{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sns:Publish"
      ],
      "Resource": [
        "arn:aws:sns:eu-west-2:${account_id}:tdr-notifications-${environment}"
      ]
    }
  ]
}
