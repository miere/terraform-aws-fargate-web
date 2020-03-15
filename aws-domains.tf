/**
 * Checks for certificate existence and defines a register A
 * entry into Route53 for our Load Balancer. 
 */
locals {
  route53_record = var.route53_record_name == "" ? local.cannonical_name : var.route53_record_name
  acm_certificate_domain = var.acm_certificate_domain == "" ? var.route53_root_domain : var.acm_certificate_domain
}

data "aws_acm_certificate" "default" {
  domain = local.acm_certificate_domain
  most_recent = true
}

data "aws_route53_zone" "default" {
  name = "${var.route53_root_domain}."
}

resource "aws_route53_record" "submain" {
  zone_id = data.aws_route53_zone.default.id
  name    = "${local.route53_record}.${var.route53_root_domain}"
  type    = "A"

  alias {
    name                   = aws_alb.default.dns_name
    zone_id                = aws_alb.default.zone_id
    evaluate_target_health = true
  }
}
