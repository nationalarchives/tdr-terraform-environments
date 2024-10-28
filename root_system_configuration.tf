locals {
  default_lambda_reserved_concurrency = -1

  consignment_export_ecs_task_download_batch_delay_ms = 10

  statuses_lambda_timeout_seconds = 30

  yara_av_v2_lambda_timeout_seconds = 300
  yara_av_v2_lambda_storage_size    = 2560
  yara_av_v2_lambda_memory_size     = 2560
}