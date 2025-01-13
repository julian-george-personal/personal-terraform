locals {
  root_domain = "juliangeorge.net"
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_zone" "primary" {
  name = local.root_domain
}

resource "aws_route53_record" "primary-name" {
  allow_overwrite = true
  name            = local.root_domain
  ttl             = 172800
  type            = "NS"
  zone_id         = aws_route53_zone.primary.zone_id

  records = aws_route53_zone.primary.name_servers
}

resource "aws_route53_record" "primary-mail" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = local.root_domain
  type    = "MX"
  ttl     = 172800
  records = ["1 aspmx.l.google.com", "5 alt1.aspmx.l.google.com", "5 alt2.aspmx.l.google.com", "10 alt3.aspmx.l.google.com", "10 alt4.aspmx.l.google.com"]
}

module "aws-apprunner-application" {
  source      = "./aws-apprunner-application"
  app_name    = "smart-guitar-chords"
  is_dns_enabled = true
  domain_name = "guitarchords.${local.root_domain}"
  hosted_zone_id = aws_route53_zone.primary.zone_id
}