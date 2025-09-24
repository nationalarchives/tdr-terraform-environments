{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sqs:SendMessage"
      ],
      "Resource": [
        "arn:aws:sqs:eu-west-2:${account_id}:tdr-aggregate-processing-${environment}"
      ]
    }
  ]
}
