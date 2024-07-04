[
  {
    "name": "transfer-service",
    "image": "${app_image}",
    "networkMode": "awsvpc",
    "secrets": [],
    "environment": [
       {
         "name": "RECORDS_UPLOAD_BUCKET",
         "value": "${records_upload_bucket}"
       },
       {
         "name": "METADATA_UPLOAD_BUCKET",
         "value": "${metadata_upload_bucket}"
       },
       {
         "name": "CONSIGNMENT_API_URL",
         "value": "${consignment_api_url}/graphql"
       },
       {
         "name": "AUTH_URL",
         "value": "${auth_url}"
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
