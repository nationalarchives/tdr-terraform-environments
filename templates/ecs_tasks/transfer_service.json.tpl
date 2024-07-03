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
