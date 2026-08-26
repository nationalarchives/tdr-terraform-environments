{
  "source": [
    "aws.ecs"
  ],
  "detail-type": [
    "ECS Task State Change"
  ],
  "detail": {
    "clusterArn": [
      "${cluster_arn}"
    ],
    "lastStatus": [
      "STOPPED"
    ],
    "containers": {
      "exitCode": [
        {
          "anything-but": [
            0
          ]
        }
      ]
    }
  }
}
