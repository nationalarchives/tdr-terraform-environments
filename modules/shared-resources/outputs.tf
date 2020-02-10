output "kms_alias_arn" {
  value = aws_kms_alias.encryption.arn
}

output "kms_key_arn" {
  value = aws_kms_key.encryption.arn
}
