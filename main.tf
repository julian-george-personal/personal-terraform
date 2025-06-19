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

module "personal-email" {
  source         = "./personal-email"
  domain_name    = local.personal_domain_name
  hosted_zone_id = module.personal-domain.hosted_zone_id
}

module "smartguitarchords" {
  source                         = "./smartguitarchords"
  personal_domain_hosted_zone_id = module.personal-domain.hosted_zone_id
  personal_domain_name           = local.personal_domain_name
}

resource "aws_s3_bucket" "static-sites" {
  bucket = "static-sites-juliangeorge"
}
