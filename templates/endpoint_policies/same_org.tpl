{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AccessWithinOrganisationOnly",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:PrincipalOrgID": "${organisation_id}",
          "aws:ResourceOrgID": "${organisation_id}"
        }
      }
    }
  ]
}
