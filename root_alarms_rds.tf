# TDRD-1268
# Alarms must be created in the management account 
# Naming convention for the alarm should be:
# <metrics_name_space> <why> <resource_triggering_alert>
# This assumes that the resource contains an account identifier.  If not add one in the alarm name

# RDS - Multiple alerts see https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Best_Practice_Recommended_Alarms_AWS_Services.html#RDS
locals {
  rds_instance_identifiers = [
    module.consignment_api_database.identifier,
    module.keycloak_database_instance.identifier
  ]
}

resource "aws_cloudwatch_metric_alarm" "tdr_alarms_rds_cpu_utilization" {
  for_each = local.environment == "prod" ? toset(local.rds_instance_identifiers) : []

  # Intent            : "This alarm is used to detect consistent high CPU utilization in order to prevent very high response time and time-outs. If you want to check micro-bursting of CPU utilization you can set a lower alarm evaluation time."
  # Threshold Justification : "Random spikes in CPU consumption may not hamper database performance, but sustained high CPU can hinder upcoming database requests. Depending on the overall database workload, high CPU at your RDS/Aurora instance can degrade the overall performance."

  alarm_description = "This alarm helps to monitor consistent high CPU utilization. CPU utilization measures non-idle time. Consider using [Enhanced Monitoring](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_Monitoring.OS.Enabling.html) or [Performance Insights](https://aws.amazon.com/rds/performance-insights/) to review which [wait time](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_Monitoring-Available-OS-Metrics.html) is consuming the most of the CPU time (`guest`, `irq`, `wait`, `nice`, etc) for MariaDB, MySQL, Oracle, and PostgreSQL. Then evaluate which queries consume the highest amount of CPU. If you cannot tune your workload, consider moving to a larger DB instance class."

  alarm_name = format("AWS/RDS CPUUtilization Environment=%s DBInstanceIdentifier=%s", local.environment, each.key)

  metric_query {
    account_id  = data.aws_caller_identity.current.id
    id          = "m1"
    return_data = "true"

    metric {
      metric_name = "CPUUtilization"
      namespace   = "AWS/RDS"
      stat        = "Average"
      period      = 60
      dimensions = {
        DBInstanceIdentifier = each.key
      }
    }
  }
  evaluation_periods  = 5
  datapoints_to_alarm = 5
  threshold           = 90
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "breaching"

  provider = aws.alarm_deployer
}

resource "aws_cloudwatch_metric_alarm" "tdr_alarms_rds_ebs_byte_balance" {
  for_each = local.environment == "prod" ? toset(local.rds_instance_identifiers) : []

  # Intent            : "This alarm is used to detect a low percentage of throughput credits remaining in the burst bucket. Low byte balance percentage can cause throughput bottleneck issues. This alarm is not recommended for Aurora PostgreSQL instances."
  # Threshold Justification : "A throughput credit balance below 10% is considered to be poor and you should set the threshold accordingly. You can also set a lower threshold if your application can tolerate a lower throughput for the workload."

  alarm_description = "This alarm helps to monitor a low percentage of throughput credits remaining. For troubleshooting, check [latency problems in RDS](https://repost.aws/knowledge-center/rds-latency-ebs-iops"

  alarm_name = format("AWS/RDS EBSByteBalance%% Environment=%s, DBInstanceIdentifier=%s", local.environment, each.key)

  metric_query {
    account_id  = data.aws_caller_identity.current.id
    id          = "m1"
    return_data = "true"

    metric {
      metric_name = "EBSByteBalance%"
      namespace   = "AWS/RDS"
      stat        = "Average"
      period      = 60
      dimensions = {
        DBInstanceIdentifier = each.key
      }
    }
  }
  evaluation_periods  = 3
  datapoints_to_alarm = 3
  threshold           = 10
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "missing"

  provider = aws.alarm_deployer
}

resource "aws_cloudwatch_metric_alarm" "tdr_alarms_rds_ebsio_balance" {
  for_each = local.environment == "prod" ? toset(local.rds_instance_identifiers) : []

  # Intent            : "This alarm is used to detect a low percentage of I/O credits remaining in the burst bucket. Low IOPS balance percentage can cause IOPS bottleneck issues. This alarm is not recommended for Aurora instances."
  # Threshold Justification : "An IOPS credits balance below 10% is considered to be poor and you can set the threshold accordingly. You can also set a lower threshold, if your application can tolerate a lower IOPS for the workload."

  alarm_description = "This alarm helps to monitor low percentage of IOPS credits remaining. For troubleshooting, see [latency problems in RDS](https://repost.aws/knowledge-center/rds-latency-ebs-iops-bottleneck)."

  alarm_name = format("AWS/RDS EBSIOBalance%% Environment=%s, DBInstanceIdentifier=%s", local.environment, each.key)

  metric_query {
    account_id  = data.aws_caller_identity.current.id
    id          = "m1"
    return_data = "true"

    metric {
      metric_name = "EBSIOBalance%"
      namespace   = "AWS/RDS"
      stat        = "Average"
      period      = 60
      dimensions = {
        DBInstanceIdentifier = each.key
      }
    }
  }
  evaluation_periods  = 3
  datapoints_to_alarm = 3
  threshold           = 10
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "missing"

  provider = aws.alarm_deployer
}

resource "aws_cloudwatch_metric_alarm" "tdr_alarms_rds_free_storage_space" {
  for_each = local.environment == "prod" ? toset(local.rds_instance_identifiers) : []

  # Missing fields    : "Threshold"
  # Intent            : "This alarm helps prevent storage full issues. This can prevent downtime that occurs when your database instance runs out of storage. We do not recommend using this alarm if you have storage auto scaling enabled, or if you frequently change the storage capacity of the database instance."
  # Threshold Justification : "The threshold value will depend on the currently allocated storage space. Typically, you should calculate the value of 10 percent of the allocated storage space and use that result as the threshold value."

  alarm_description = "This alarm watches for a low amount of available storage space. Consider scaling up your database storage if you frequently approach storage capacity limits. Include some buffer to accommodate unforeseen increases in demand from your applications. Alternatively, consider enabling RDS storage auto scaling. Additionally, consider freeing up more space by deleting unused or outdated data and logs. For further information, check [RDS run out of storage document](https://repost.aws/knowledge-center/rds-out-of-storage) and [PostgreSQL storage issues document](https://repost.aws/knowledge-center/diskfull-error-rds-postgresql)."

  alarm_name = format("AWS/RDS FreeStorageSpace Environment=%s, DBInstanceIdentifier=%s", local.environment, each.key)

  metric_query {
    account_id  = data.aws_caller_identity.current.id
    id          = "m1"
    return_data = "true"

    metric {
      metric_name = "FreeStorageSpace"
      namespace   = "AWS/RDS"
      stat        = "Average"
      period      = 60
      dimensions = {
        DBInstanceIdentifier = each.key
      }
    }
  }
  evaluation_periods  = 5
  datapoints_to_alarm = 5
  threshold           = 30
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "breaching"

  provider = aws.alarm_deployer
}

resource "aws_cloudwatch_metric_alarm" "tdr_alarms_rds_read_latency" {
  for_each = local.environment == "prod" ? toset(local.rds_instance_identifiers) : []

  # Missing fields    : "Threshold"
  # Intent            : "This alarm is used to detect high read latency. Database disks normally have a low read/write latency, but they can have issues that can cause high latency operations."
  # Threshold Justification : "The recommended threshold value for this alarm is highly dependent on your use case. Read latencies higher than 20 milliseconds are likely a cause for investigation. You can also set a higher threshold if your application can have higher latency for read operations. Review the criticality and requirements of read latency and analyze the historical behavior of this metric to determine sensible threshold levels."

  alarm_description = "This alarm helps to monitor high read latency. If storage latency is high, it's because the workload is exceeding resource limits. You can review I/O utilization relative to instance and allocated storage configuration. Refer to [troubleshoot the latency of Amazon EBS volumes caused by an IOPS bottleneck](https://repost.aws/knowledge-center/rds-latency-ebs-iops-bottleneck). For Aurora, you can switch to an instance class that has [I/O-Optimized storage configuration](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Concepts.Aurora_Fea_Regions_DB-eng.Feature.storage-type.html). See [Planning I/O in Aurora](https://aws.amazon.com/blogs/database/planning-i-o-in-amazon-aurora/) for guidance."

  alarm_name = format("AWS/RDS ReadLatency Environment=%s, DBInstanceIdentifier=%s", local.environment, each.key)

  metric_query {
    account_id  = data.aws_caller_identity.current.id
    id          = "m1"
    return_data = "true"

    metric {
      metric_name = "ReadLatency"
      namespace   = "AWS/RDS"
      period      = 60
      stat        = "p90"
      dimensions = {
        DBInstanceIdentifier = each.key
      }
    }
  }

  evaluation_periods  = 5
  datapoints_to_alarm = 5
  threshold           = 0.002
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "missing"

  provider = aws.alarm_deployer
}

resource "aws_cloudwatch_metric_alarm" "tdr_alarms_rds_write_latency" {
  for_each = local.environment == "prod" ? toset(local.rds_instance_identifiers) : []

  # Missing fields    : "Threshold"
  # Intent            : "This alarm is used to detect high write latency. Although database disks typically have low read/write latency, they may experience problems that cause high latency operations. Monitoring this will assure you the disk latency is as low as expected."
  # Threshold Justification : "The recommended threshold value for this alarm is highly dependent on your use case. Write latencies higher than 20 milliseconds are likely a cause for investigation. You can also set a higher threshold if your application can have a higher latency for write operations. Review the criticality and requirements of write latency and analyze the historical behavior of this metric to determine sensible threshold levels."

  alarm_description = "This alarm helps to monitor high write latency. If storage latency is high, it's because the workload is exceeding resource limits. You can review I/O utilization relative to instance and allocated storage configuration. Refer to [troubleshoot the latency of Amazon EBS volumes caused by an IOPS bottleneck](https://repost.aws/knowledge-center/rds-latency-ebs-iops-bottleneck). For Aurora, you can switch to an instance class that has [I/O-Optimized storage configuration](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Concepts.Aurora_Fea_Regions_DB-eng.Feature.storage-type.html). See [Planning I/O in Aurora](https://aws.amazon.com/blogs/database/planning-i-o-in-amazon-aurora/) for guidance."

  alarm_name = format("AWS/RDS WriteLatency Environment=%s, DBInstanceIdentifier=%s", local.environment, each.key)

  metric_query {
    account_id  = data.aws_caller_identity.current.id
    id          = "m1"
    return_data = "true"

    metric {
      metric_name = "WriteLatency"
      namespace   = "AWS/RDS"
      period      = 60
      stat        = "p90"
      dimensions = {
        DBInstanceIdentifier = each.key
      }
    }
  }

  evaluation_periods  = 5
  datapoints_to_alarm = 5
  threshold           = 0.020
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "missing"

  provider = aws.alarm_deployer
}
