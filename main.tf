locals {
  personal_domain_name = "juliangeorge.net"
}

provider "aws" {
  region = "us-east-1"
}

module "personal-domain" {
  source      = "./aws-route53-domain"
  domain_name = local.personal_domain_name
}

resource "aws_route53_record" "personal-mail" {
  zone_id = module.personal-domain.hosted_zone_id
  name    = local.personal_domain_name
  type    = "MX"
  ttl     = 172800
  records = ["1 aspmx.l.google.com", "5 alt1.aspmx.l.google.com", "5 alt2.aspmx.l.google.com", "10 alt3.aspmx.l.google.com", "10 alt4.aspmx.l.google.com"]
}

module "smartguitarchords" {
  source                         = "./smartguitarchords"
  personal_domain_hosted_zone_id = module.personal-domain.hosted_zone_id
  personal_domain_name           = local.personal_domain_name
}
