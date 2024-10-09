[
  {
    "name": "transfer-service",
    "image": "${app_image}",
    "networkMode": "awsvpc",
    "secrets": [],
    "environment": [
       {
         "name": "AWS_REGION",
         "value": "${aws_region}"
       },
       {
         "name": "RECORDS_UPLOAD_BUCKET_ARN",
         "value": "${records_upload_bucket_arn}"
       },
       {
         "name": "RECORDS_UPLOAD_BUCKET_NAME",
         "value": "${records_upload_bucket_name}"
       },
       {
         "name": "METADATA_UPLOAD_BUCKET_ARN",
         "value": "${metadata_upload_bucket_arn}"
       },
       {
         "name": "METADATA_UPLOAD_BUCKET_NAME",
         "value": "${metadata_upload_bucket_name}"
       },
       {
         "name": "CONSIGNMENT_API_URL",
         "value": "${consignment_api_url}/graphql"
       },
       {
         "name": "AUTH_URL",
         "value": "${auth_url}"
       },
       {
         "name": "API_PORT",
         "value": "${transfer_service_api_port}"
       }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${log_group_name}",
        "awslogs-region": "${aws_region}",
        "awslogs-stream-prefix": "ecs"
      }
    },
    "portMappings": [
      {
        "containerPort": 8080,
        "hostPort": 8080
      }
    ]
  }
]
