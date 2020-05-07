{
  "Version":"2012-10-17",
  "Statement":[{
    "Effect": "Allow",
    "Principal": {"AWS":"*"},
    "Action": "SNS:Publish",
    "Resource": "arn:aws:sns:*:*:${topic_name}",
    "Condition":{
      "ArnEquals":{"aws:SourceArn":"${source_arn}"}
    }
  }]
}