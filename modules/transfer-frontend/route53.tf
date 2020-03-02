resource "aws_route53_record" "frontend_dns" {
  name    = ""
  type    = "A"
  zone_id = var.dns_zone_id
  alias {
    evaluate_target_health = false
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
  }
}