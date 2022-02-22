{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetObject",
        "s3:ListBucket",
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::tdr-releases-mgmt",
        "arn:aws:s3:::tdr-releases-mgmt/*",
        "arn:aws:s3:::tdr-snapshots-mgmt",
        "arn:aws:s3:::tdr-snapshots-mgmt/*"
      ],
      "Sid": ""
    }
  ]
}
