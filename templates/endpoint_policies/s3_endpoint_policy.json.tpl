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
        "s3:DeleteBucket",
        "s3:DeleteBucketPolicy",
        "s3:DeleteObject",
        "s3:DeleteObjectTagging",
        "s3:DeleteObjectVersion",
        "s3:DeleteObjectVersionTagging",
        "s3:GetBucketAcl",
        "s3:GetBucketLocation",
        "s3:GetBucketLogging",
        "s3:GetBucketNotification",
        "s3:GetBucketObjectLockConfiguration",
        "s3:GetBucketPolicy",
        "s3:GetBucketPolicyStatus",
        "s3:GetBucketPublicAccessBlock",
        "s3:GetBucketTagging",
        "s3:GetBucketVersioning",
        "s3:GetBucketWebsite",
        "s3:GetEncryptionConfiguration",
        "s3:GetLifecycleConfiguration",
        "s3:GetObject",
        "s3:GetObjectAcl",
        "s3:GetObjectTagging",
        "s3:GetObjectVersion",
        "s3:GetReplicationConfiguration",
        "s3:ListAllMyBuckets",
        "s3:ListBucket",
        "s3:ListBucketVersions",
        "s3:PutBucketAcl",
        "s3:PutBucketPublicAccessBlock",
        "s3:PutBucketTagging",
        "s3:PutBucketTagging",
        "s3:PutObjectAcl",
        "s3:PutObjectVersionAcl"
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