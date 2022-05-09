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
        "${cluster_arn}",
        "${task_definition_arn}",
        ${role_arns}
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
