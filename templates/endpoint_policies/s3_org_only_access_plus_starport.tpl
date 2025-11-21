{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3AccessWithinOrgOnly",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:PrincipalOrgID": "${org_id}",
          "aws:ResourceOrgID": "${org_id}"
        }
      }
    },
    {
      "Sid": "AccessAwsEcrDockerImages",
      "Principal": "*",
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::prod-${region}-starport-layer-bucket/*"
      ]
    }
  ]
}
