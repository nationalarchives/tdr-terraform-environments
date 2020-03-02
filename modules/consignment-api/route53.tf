resource "aws_route53_record" "api_dns" {
  name    = "api"
  type    = "A"
  zone_id = var.dns_zone_id
  alias {
    evaluate_target_health = false
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
  }
}