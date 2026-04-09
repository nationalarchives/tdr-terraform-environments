resource "random_password" "password" {
  length  = 41
  special = false
}

resource "random_string" "snapshot_prefix" {
  length  = 4
  upper   = false
  special = false
}
