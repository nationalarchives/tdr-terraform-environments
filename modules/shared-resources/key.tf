resource "aws_kms_key" "encryption" {
  description         = "KMS key for encryption within the environment"
  enable_key_rotation = true
  tags = merge(
    var.common_tags,
    map(
      "Name", "environment-encryption-${var.environment}"
    )
  )
}

resource "aws_kms_alias" "encryption" {
  name          = "alias/environment-encryption-${var.environment}"
  target_key_id = aws_kms_key.encryption.key_id
}