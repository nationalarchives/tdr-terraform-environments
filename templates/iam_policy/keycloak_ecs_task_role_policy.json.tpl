{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sns:Publish",
        "rds-db:connect",
        "kms:Decrypt",
        "kms:GenerateDataKey"
      ],
      "Resource": [
        "${kms_arn}",
        "arn:aws:rds-db:eu-west-2:${account_id}:dbuser:${instance_resource_id}/keycloak_user",
        "arn:aws:sns:eu-west-2:${account_id}:tdr-notifications-${environment}"
      ]
    }
  ]
}
