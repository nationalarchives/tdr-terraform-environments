{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": ${jsonencode(export_access_principals)}
      },
      "Action": "sts:AssumeRole",
      "Condition": {}
    }
  ]
}