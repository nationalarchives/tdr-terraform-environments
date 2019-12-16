resource "random_password" "play_secret" {
  length = 32
}

resource "aws_ssm_parameter" "play_secret" {
  name  = "/${var.environment}/frontend/play_secret"
  type  = "String"
  value = random_password.play_secret.result
}