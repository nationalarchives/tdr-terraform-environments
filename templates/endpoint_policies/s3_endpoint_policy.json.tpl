{
  "Statement": [
    {
      "Sid": "restrict-access-dirty-bucket-download",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::tdr-upload-files-cloudfront-dirty-intg/*",
      "Condition": {
        "ArnEquals": {
          "aws:PrincipalArn": [
            "arn:aws:iam::${account_id}:role/TDRDownloadFilesRole",
            "arn:aws:iam::${account_id}:role/TDRYaraAvRole"
          ]
        }
      }
    },
    {
      "Sid": "restrict-access-av-move-files",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::${upload_bucket_name}/*",
        "arn:aws:s3:::${upload_bucket_name}",
        "arn:aws:s3:::${quarantine_bucket_name}/*",
        "arn:aws:s3:::${quarantine_bucket_name}"
      ],
      "Condition": {
        "ArnEquals": {
          "aws:PrincipalArn": [
            "${antivirus_role}"
          ]
        }
      }
    },
    {
      "Sid": "restrict-acess-to-export-role",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::${upload_bucket_name}/*",
        "arn:aws:s3:::${export_bucket_name}/*"
      ],
      "Condition": {
        "ArnEquals": {
          "aws:PrincipalArn": [
            "${export_task_role}"
          ]
        }
      }
    },
    {
      "Sid": "restrict-acess-to-cloud-custodian",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "*"
      ],
      "Condition": {
        "ArnEquals": {
          "aws:PrincipalArn": [
            "arn:aws:iam::${account_id}:role/CustodianDeleteMarkedS3",
            "arn:aws:iam::${account_id}:role/CustodianMarkUnencryptedS3",
            "arn:aws:iam::${account_id}:role/CustodianS3CheckPublicBlock",
            "arn:aws:iam::${account_id}:role/CustodianS3PublicAccess",
            "arn:aws:iam::${account_id}:role/CustodianS3RemovePublicAcl",
            "arn:aws:iam::${account_id}:role/CustodianUnmarkEncryptedS3"
          ]
        }
      }
    }
  ]
}