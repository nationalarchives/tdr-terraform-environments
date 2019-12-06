//resource "aws_route53_zone" "main" {
//  name = "nationalarchives.gov.uk"
//}
//
//variable "environment_to_suffix_map" {
//  type = map
//
//  default = {
//    intg    = "-integration"
//    staging = "-staging"
//    test    = "-test"
//    prod    = ""
//  }
//}
//
//resource "aws_route53_record" "www" {
//  zone_id = aws_route53_zone.main.zone_id
//  name    = "transfer${lookup(var.environment_to_suffix_map, var.environment)}"
//  type    = "A"
//
//  alias {
//    name                   = aws_alb.main.dns_name
//    zone_id                = aws_alb.main.zone_id
//    evaluate_target_health = true
//  }
//}