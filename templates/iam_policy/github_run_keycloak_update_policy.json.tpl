{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "ecs:DescribeTasks",
        "ecs:ListContainerInstances",
        "ecs:RunTask",
        "ecs:StopTask",
        "iam:PassRole"
      ],
      "Resource": [
        "arn:aws:ecs:eu-west-2:${account_id}:cluster/keycloak_update_${environment}",
        "arn:aws:ecs:${region}:${account_id}:task-definition/keycloak-update-${environment}",
        "arn:aws:iam::${account_id}:role/TDRKeycloakUpdateECSExecutionRole${title(environment)}"
      ]
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups"
      ],
      "Resource": "*"
    }
  ]
}
