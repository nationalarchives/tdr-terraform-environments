{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:CreateTags",
        "ec2:RevokeSecurityGroupIngress",
        "wafv2:UpdateRuleGroup"
      ],
      "Resource": [
        "${ip_set_arn}",
        "${rule_group_arn}",
        "arn:aws:ec2:eu-west-2:${account_id}:security-group/${security_group_id}",
        "arn:aws:wafv2:eu-west-2:${account_id}:REGIONAL/regexpatternset/*/*"
      ]
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeSecurityGroups",
        "wafv2:ListIPSets",
        "wafv2:ListRuleGroups"
      ],
      "Resource": "*"
    }
  ]
}
