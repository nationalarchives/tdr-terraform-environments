locals {
  topic_name = "${var.sns_topic_name_prefix}-${var.environment}"
}

data "template_file" "sns_topic_delivery_policy" {
  //Currently just default policy
  template = file("${path.module}/templates/sns_topic_delivery_policy.json.tpl")
}

data "template_file" "sns_topic_policy" {
  //Provides permission for the dirty s3 bucket to publish events to the topic
  template = file("${path.module}/templates/sns_topic_policy.json.tpl")

  vars = {
    topic_name = local.topic_name
    source_arn = var.s3_dirty_upload_bucket_arn
  }
}

resource "aws_sns_topic" "s3_dirty_upload" {
  name            = local.topic_name
  policy          = data.template_file.sns_topic_policy.rendered
  delivery_policy = data.template_file.sns_topic_delivery_policy.rendered
  tags = merge(
    var.common_tags,
    map("Name", local.topic_name)
  )
}

