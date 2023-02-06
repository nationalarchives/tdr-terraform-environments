{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::tdr-consignment-export-${environment}/*",
        "arn:aws:s3:::tdr-consignment-export-judgment-${environment}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::tdr-upload-files-${environment}/*"
      ]
    }
  ]
}
