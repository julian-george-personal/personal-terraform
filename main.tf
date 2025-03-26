locals {
  root_domain = "juliangeorge.net"
  smartguitarchords_domain = "smartguitarchords.com"
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

resource "aws_route53_zone" "smartguitarchords" {
  name = local.smartguitarchords_domain
}

resource "aws_route53_record" "smartguitarchords-name" {
  allow_overwrite = true
  name            = local.root_domain
  ttl             = 172800
  type            = "NS"
  zone_id         = aws_route53_zone.smartguitarchords.zone_id

  records = aws_route53_zone.smartguitarchords.name_servers
}

module "aws-apprunner-application" {
  source         = "./aws-apprunner-application"
  app_name       = "smart-guitar-chords"
}

module "smartguitarchords-dns-primary" {
  source = "./aws-apprunner-dns"
  hosted_zone_id=aws_route53_zone.primary.zone_id
  domain_name = "guitarchords.${local.root_domain}"
  apprunner_arn = module.aws-apprunner-application.arn
}

module "smartguitarchords-dns-smartguitarchords" {
  source = "./aws-apprunner-dns"
  hosted_zone_id=aws_route53_zone.smartguitarchords.zone_id
  domain_name = local.smartguitarchords_domain
  apprunner_arn = module.aws-apprunner-application.arn
}

