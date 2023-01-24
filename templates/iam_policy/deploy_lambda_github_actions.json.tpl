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
        "arn:aws:lambda:${region}:${account_id}:function:tdr-api-update-${environment}",
        "arn:aws:lambda:${region}:${account_id}:function:tdr-api-update-v2-${environment}",
        "arn:aws:lambda:${region}:${account_id}:function:tdr-backend-checks-results-${environment}",
        "arn:aws:lambda:${region}:${account_id}:function:tdr-checksum-${environment}",
        "arn:aws:lambda:${region}:${account_id}:function:tdr-checksum-v2-${environment}",
        "arn:aws:lambda:${region}:${account_id}:function:tdr-create-bastion-user-${environment}",
        "arn:aws:lambda:${region}:${account_id}:function:tdr-create-db-users-${environment}",
        "arn:aws:lambda:${region}:${account_id}:function:tdr-create-keycloak-db-user-new-${environment}",
        "arn:aws:lambda:${region}:${account_id}:function:tdr-create-keycloak-user-api-${environment}",
        "arn:aws:lambda:${region}:${account_id}:function:tdr-create-keycloak-user-s3-${environment}",
        "arn:aws:lambda:${region}:${account_id}:function:tdr-database-migrations-${environment}",
        "arn:aws:lambda:${region}:${account_id}:function:tdr-download-files-${environment}",
        "arn:aws:lambda:${region}:${account_id}:function:tdr-export-api-authoriser-${environment}",
        "arn:aws:lambda:${region}:${account_id}:function:tdr-export-status-update-${environment}",
        "arn:aws:lambda:${region}:${account_id}:function:tdr-file-format-${environment}",
        "arn:aws:lambda:${region}:${account_id}:function:tdr-file-format-v2-${environment}",
        "arn:aws:lambda:${region}:${account_id}:function:tdr-file-upload-data-${environment}",
        "arn:aws:lambda:${region}:${account_id}:function:tdr-log-data-${environment}",
        "arn:aws:lambda:${region}:${account_id}:function:tdr-notifications-${environment}",
        "arn:aws:lambda:${region}:${account_id}:function:tdr-redacted-files-${environment}",
        "arn:aws:lambda:${region}:${account_id}:function:tdr-reporting-${environment}",
        "arn:aws:lambda:${region}:${account_id}:function:tdr-rotate-keycloak-secrets-${environment}",
        "arn:aws:lambda:${region}:${account_id}:function:tdr-service-unavailable-${environment}",
        "arn:aws:lambda:${region}:${account_id}:function:tdr-signed-cookies-${environment}",
        "arn:aws:lambda:${region}:${account_id}:function:tdr-statuses-${environment}",
        "arn:aws:lambda:${region}:${account_id}:function:tdr-yara-av-${environment}",
        "arn:aws:lambda:${region}:${account_id}:function:tdr-yara-av-v2-${environment}",
        "arn:aws:s3:::tdr-backend-code-mgmt/*"
      ]
    }
  ]
}
