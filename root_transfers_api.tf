module "transfers_api_certificate" {
  source      = "./tdr-terraform-modules/certificatemanager"
  project     = var.project
  function    = "transfers-api"
  dns_zone    = local.environment_domain
  domain_name = "transfers-api.${local.environment_domain}"
  common_tags = local.common_tags
}