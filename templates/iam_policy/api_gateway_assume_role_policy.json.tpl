{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    },
    {
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole",
      "Effect": "Deny",
      "Condition": {
        "StringNotEquals": {
          "aws:ResourceAccount": [
            "${account_id}"
          ]
        }
      }
    }
  ]
}
