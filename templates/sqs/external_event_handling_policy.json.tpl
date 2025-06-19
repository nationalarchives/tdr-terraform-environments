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
        "SQS:GetQueueAttributes",
        "SQS:GetQueueUrl",
        "SQS:ListDeadLetterSourceQueues",
        "SQS:ReceiveMessage",
        "SQS:SendMessage"
      ],
      "Resource": "arn:aws:sqs:${region}:${account_id}:${sqs_name}",
      "Condition": {
                "StringEquals": {
                  "aws:PrincipalAccount" : "${account_id}"
                }
      }
    },
    {
      "Sid": "DR2IngestSubscription",
      "Effect": "Allow",
      "Principal": {
             "AWS": "arn:aws:iam::${dr2_account_id}:root"
      },
      "Action": "SQS:SendMessage",
      "Resource": "arn:aws:sqs:${region}:${account_id}:${sqs_name}",
      "Condition": {
                "ArnEquals": {
                  "aws:SourceArn": "arn:aws:sns:${region}:${dr2_account_id}:${dr2_ingest_topic}"
                }
      }
    }
  ]
}
