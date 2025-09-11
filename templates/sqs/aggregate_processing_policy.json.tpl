{
  "Version": "2012-10-17",
  "Id": "sqs_queue_policy",
  "Statement": [
    {
      "Sid": "RestrictedAccess",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${account_id}:root"
      },
      "Action": [
        "sqs:GetQueueAttributes",
        "sqs:GetQueueUrl",
        "sqs:ListDeadLetterSourceQueues",
        "sqs:ReceiveMessage",
        "sqs:SendMessage"
      ],
      "Resource": "arn:aws:sqs:${region}:${account_id}:${sqs_queue_name}",
      "Condition": {
        "StringEquals": {
          "aws:PrincipalAccount": "${account_id}"
        }
      }
    }
  ]
}
