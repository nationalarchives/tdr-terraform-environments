{
  "Version": "2012-10-17",
  "Statement": [
   {
         "Effect": "Allow",
         "Action": [
           "kms:Decrypt",
           "kms:GenerateDataKey",
           "sns:Publish"
         ],
         "Resource": [
           "arn:aws:kms:eu-west-2:229554778675:key/b05401ed-cc76-46f6-bf2c-76cb0a859542",
           "arn:aws:sns:eu-west-2:${account_id}:tdr-notifications-${environment}"
         ]
       }
   ]
}

