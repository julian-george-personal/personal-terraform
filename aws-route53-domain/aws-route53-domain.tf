resource "aws_route53_zone" "zone" {
  name = var.domain_name
}

resource "aws_route53_record" "record" {
  allow_overwrite = true
  name            = var.domain_name
  ttl             = 172800
  type            = "NS"
  zone_id         = aws_route53_zone.zone.zone_id

  records = aws_route53_zone.zone.name_servers
}