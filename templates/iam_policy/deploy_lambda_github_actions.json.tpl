{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "lambda:GetFunctionConfiguration",
        "lambda:InvokeFunction",
        "lambda:PublishVersion",
        "lambda:UpdateEventSourceMapping",
        "lambda:UpdateFunctionCode",
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:lambda:${region}:${account_id}:event-source-mapping:*",
        "arn:aws:lambda:${region}:${account_id}:function:tdr-create-keycloak-user-api-${environment}",
        "arn:aws:lambda:${region}:${account_id}:function:tdr-create-keycloak-user-s3-${environment}",
        "arn:aws:lambda:${region}:${account_id}:function:tdr-checksum-${environment}",
        "arn:aws:s3:::tdr-backend-code-mgmt/*"
      ]
    }
  ]
}
