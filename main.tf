terraform {
  required_providers {
    sendgrid = {
      source = "indentinc/sendgrid"
    }
    aws = {
      source = "hashicorp/aws"
    }
  }
}

locals {
  personal_domain_name = "juliangeorge.net"
}

provider "aws" {
  region = "us-east-1"
}

provider "sendgrid" {}

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

resource "aws_secretsmanager_secret" "dkim_secret" {
  name = "dkim-record-${local.personal_domain_name}"
}

data "aws_secretsmanager_secret_version" "dkim_secret_latest" {
  secret_id = aws_secretsmanager_secret.dkim_secret.id
}

resource "aws_route53_record" "dkim_record" {
  zone_id = module.personal-domain.hosted_zone_id
  name    = "google._domainkey.${local.personal_domain_name}"
  type    = "TXT"
  ttl     = 3600
  records = [data.aws_secretsmanager_secret_version.dkim_secret_latest.secret_string]
}

resource "aws_route53_record" "spf_record" {
  zone_id = module.personal-domain.hosted_zone_id
  name    = local.personal_domain_name
  type    = "TXT"
  ttl     = 3600
  records = ["v=spf1 include:_spf.google.com ~all"]
}

module "smartguitarchords" {
  source                         = "./smartguitarchords"
  personal_domain_hosted_zone_id = module.personal-domain.hosted_zone_id
  personal_domain_name           = local.personal_domain_name
}
