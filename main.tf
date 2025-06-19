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
  personal_domain_name     = "juliangeorge.net"
  static_sites_bucket_name = "static-sites-juliangeorge"
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
  bucket = local.static_sites_bucket_name
}

module "portfolio" {
  source             = "./aws-s3-application"
  application_name   = "portfolio"
  bucket_domain_name = aws_s3_bucket.static-sites.bucket_domain_name
  hosted_zone_id     = module.personal-domain.hosted_zone_id
  app_domain_name    = local.personal_domain_name
  bucket_name        = local.static_sites_bucket_name
}

module "viberance" {
  source             = "./aws-s3-application"
  application_name   = "viberance"
  bucket_domain_name = aws_s3_bucket.static-sites.bucket_domain_name
  hosted_zone_id     = module.personal-domain.hosted_zone_id
  app_domain_name    = "viberance.${local.personal_domain_name}"
  bucket_name        = local.static_sites_bucket_name
}

data "aws_iam_policy_document" "combined_policy" {
  source_policy_documents = [
    module.portfolio.s3_policy_json,
    module.viberance.s3_policy_json,
  ]
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = local.static_sites_bucket_name
  policy = data.aws_iam_policy_document.combined_policy.json
}