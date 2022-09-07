{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter"
      ],
      "Resource": [
        "arn:aws:ssm:eu-west-2:${account_id}:parameter/${environment}/keycloak/backend_checks_client/secret",
        "arn:aws:ssm:eu-west-2:${account_id}:parameter/${environment}/keycloak/user_admin_client/secret"
      ]
    }
  ]
}
