{
  "Version": "2008-10-17",
  "Id": "export_notifications_topic",
  "Statement": [
    {
      "Sid": "SNSAllowExportToPublish",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${export_role}"
      },
      "Action": "sns:Publish",
      "Resource": "arn:aws:sns:${region}:${account_id}:${topic_name}"
    },
    {
      "Sid": "SNSAllowDR2ToSubscribe",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${dr2_account_number}"
      },
      "Action": "sns:Subscribe",
      "Resource": "arn:aws:sns:${region}:${account_id}:${topic_name}"
    }
  ]
}
