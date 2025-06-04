{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "${service}"
      },
      "Condition": {
        "StringEquals": {
          "aws:SourceAccount": "${account_id}"
        }
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
