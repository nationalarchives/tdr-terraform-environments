import {
  to = module.iam_group.aws_iam_account_password_policy.cis_benchmark[0]
  id = "iam-account-password-policy"
}

import {
  to = module.iam_group.aws_iam_group.support[0]
  id = "support"
}

import {
  to = module.iam_group.aws_iam_group_policy_attachment.support_policy_attach[0]
  id = "support/arn:aws:iam::aws:policy/AWSSupportAccess"
}
