{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "ec2:RevokeSecurityGroupIngress",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:CreateTags",
        "wafv2:UpdateRuleGroup"
      ],
      "Resource": [
        "${ip_set_arn}",
        "${rule_group_arn}",
        "arn:aws:wafv2:eu-west-2:${account_id}:REGIONAL/regexpatternset/*/*",
        "arn:aws:ec2:eu-west-2:${account_id}:security-group/${security_group_id}"
      ]
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "wafv2:ListRuleGroups",
        "wafv2:ListIPSets",
        "ec2:DescribeSecurityGroups"
      ],
      "Resource": "*"
    }
  ]
}
