resource "aws_route53_zone" "primary" {
  name = var.domain_name
}

resource "aws_route53_record" "primary-name" {
  allow_overwrite = true
  name            = var.domain_name
  ttl             = 172800
  type            = "NS"
  zone_id         = aws_route53_zone.primary.zone_id

  records = aws_route53_zone.primary.name_servers
}