data "aws_route53_zone" "frontend_dns_zone" {
  name = "tdr-${var.environment_full_name}.nationalarchives.gov.uk"
  tags = merge(
  var.common_tags,
  map(
  "Name", "frontend-dns-zone-${var.environment}"
  )
  )
}

resource "aws_route53_record" "frontend_dns" {
  name    = ""
  type    = "A"
  zone_id = data.aws_route53_zone.frontend_dns_zone.zone_id
  alias {
    evaluate_target_health = false
    name                   = aws_alb.main.dns_name
    zone_id                = aws_alb.main.zone_id
  }
}