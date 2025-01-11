provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_zone" "primary" {
  name = "juliangeorge.net"
}

module "aws-apprunner-application" {
  source = "./aws-apprunner-application"
  app_name = "smart-guitar-chords"
}