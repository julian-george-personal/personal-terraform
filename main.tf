provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_zone" "primary" {
  name = "juliangeorge.net"
}

module "smart-guitar-chords" {
  source = "./smart-guitar-chords"
  is_enabled = true
}