{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "lambda:InvokeFunction"
      ],
      "Resource": [
        "arn:aws:lambda:eu-west-2:${account_id}:function:tdr-create-bastion-user-${environment}"
      ]
    }
  ]
}
