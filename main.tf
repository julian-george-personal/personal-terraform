provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_zone" "primary" {
  name = "juliangeorge.net"
}

module "smart-guitar-chords" {
  source = "./ecs-application"
  app_name="smart-guitar-chords"
  count = 1
}