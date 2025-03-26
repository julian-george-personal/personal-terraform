locals {
  root_domain_name              = "juliangeorge.net"
  smartguitarchords_domain_name = "smartguitarchords.com"
}

provider "aws" {
  region = "us-east-1"
}

module "primary-domain" {
  source      = "./aws-route53-domain"
  domain_name = local.root_domain_name
}

resource "aws_route53_record" "primary-mail" {
  zone_id = module.primary-domain.zone_id
  name    = local.root_domain_name
  type    = "MX"
  ttl     = 172800
  records = ["1 aspmx.l.google.com", "5 alt1.aspmx.l.google.com", "5 alt2.aspmx.l.google.com", "10 alt3.aspmx.l.google.com", "10 alt4.aspmx.l.google.com"]
}

module "smartguitarchords-domain" {
  source      = "./aws-route53-domain"
  domain_name = local.smartguitarchords_domain_name
}

module "smartguitarchords-application" {
  source   = "./aws-apprunner-application"
  app_name = "smart-guitar-chords"
}

module "smartguitarchords-dns-primary" {
  source         = "./aws-apprunner-dns"
  depends_on     = [module.smartguitarchords-application]
  hosted_zone_id = module.primary-domain.zone_id
  domain_name    = "guitarchords.${local.root_domain_name}"
  apprunner_arn  = module.smartguitarchords-application.arn
}

module "smartguitarchords-dns-smartguitarchords" {
  source         = "./aws-apprunner-dns"
  depends_on     = [module.smartguitarchords-application]
  hosted_zone_id = module.smartguitarchords-domain.zone_id
  domain_name    = local.smartguitarchords_domain_name
  apprunner_arn  = module.smartguitarchords-application.arn
}

