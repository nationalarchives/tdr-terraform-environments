{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AccessWithinOrganisationOnly",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "ecr:*",
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:PrincipalOrgID": "${organisation_id}",
          "aws:ResourceOrgID": "${organisation_id}"
        }
      }
    },
    {
      "Sid": "GetAuthorizationTokenWithinOrganisationOnly",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "ecr:GetAuthorizationToken",
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:PrincipalOrgID": "${organisation_id}"
        }
      }
    },
    {
      "Sid": "PullGuardDutyFargateAgentImage",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer"
      ],
      "Resource": "${aws_guardduty_ecr_arn}",
      "Condition": {
        "StringEquals": {
          "aws:PrincipalOrgID": "${organisation_id}"
        }
      }
    }
  ]
}
