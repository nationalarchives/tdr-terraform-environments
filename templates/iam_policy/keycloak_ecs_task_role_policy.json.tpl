{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:GenerateDataKey",
        "rds-db:connect",
        "sns:Publish"
      ],
      "Resource": [
        "${kms_arn}",
        "arn:aws:rds-db:eu-west-2:${account_id}:dbuser:${instance_resource_id}/keycloak_user",
        "arn:aws:sns:eu-west-2:${account_id}:tdr-notifications-${environment}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter"
      ],
        "Resource": [
          "arn:aws:ssm:eu-west-2:${account_id}:parameter${govuk_notify_api_key_path}",
          "arn:aws:ssm:eu-west-2:${account_id}:parameter${govuk_notify_template_id_path}"
        ]
    }
  ]
}
