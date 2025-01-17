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
        "wafv2:UpdateRuleGroup",
        "wafv2:Get*",
        "wafv2:List*",
        "wafv2:UpdateIPSet",
        "wafv2:DeleteIPSet"
      ],
      "Resource": [
        "${ip_set_arn}",
        "${rule_group_arn}",
         %{ if blocked_ip_set_arn != "" }"${blocked_ip_set_arn}",%{ endif }
        "arn:aws:ec2:eu-west-2:${account_id}:security-group/${security_group_id}",
        "arn:aws:wafv2:eu-west-2:${account_id}:REGIONAL/regexpatternset/*/*",
        "arn:aws:wafv2:eu-west-2:${account_id}:regional/ipset/tdr-apps-${environment}-whitelist/*"
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
