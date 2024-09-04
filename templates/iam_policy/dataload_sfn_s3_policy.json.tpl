{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObjectTagging",
        "s3:ListBucket"
      ],
      "Resource": ${s3_resources}
    }
  ]
}
