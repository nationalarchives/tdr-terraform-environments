{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": "ecs:UpdateService",
      "Resource": [
        "arn:aws:ecs:${region}:${account_id}:service/keycloak_${environment}/keycloak_service_${environment}",
        "arn:aws:ecs:${region}:${account_id}:service/frontend_${environment}/frontend_service_${environment}",
        "arn:aws:ecs:${region}:${account_id}:service/consignmentapi_${environment}/consignmentapi_service_${environment}"
      ]
    }
  ]
}
