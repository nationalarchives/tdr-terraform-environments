{
  "Statement": [
    {
      "Action": [
        "s3:PutObject",
        "s3:ListBucket",
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::tdr-snapshots-mgmt/*",
        "arn:aws:s3:::tdr-snapshots-mgmt",
        "arn:aws:s3:::tdr-releases-mgmt/*",
        "arn:aws:s3:::tdr-releases-mgmt"
      ],
      "Sid": ""
    }
  ],
  "Version": "2012-10-17"
}