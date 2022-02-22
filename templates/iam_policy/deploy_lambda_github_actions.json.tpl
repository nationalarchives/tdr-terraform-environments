{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "lambda:UpdateFunctionCode",
        "lambda:UpdateEventSourceMapping",
        "lambda:PublishVersion",
        "lambda:InvokeFunction",
        "lambda:GetFunctionConfiguration",
        "iam:PassRole",
        "ecs:RunTask"
      ],
      "Resource": [
        "arn:aws:s3:::tdr-backend-code-mgmt/*",
        "arn:aws:lambda:${region}:${account_id}:function:tdr-create-keycloak-user-s3-${environment}",
        "arn:aws:lambda:${region}:${account_id}:function:tdr-create-keycloak-user-api-${environment}",
        "arn:aws:lambda:${region}:${account_id}:event-source-mapping:*"
      ]
    }
  ]
}
