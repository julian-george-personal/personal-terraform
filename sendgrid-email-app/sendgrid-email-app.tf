terraform {
  required_providers {
    sendgrid = {
      source = "indentinc/sendgrid"
    }
  }
}

resource "sendgrid_domain_authentication" "default" {
  domain             = var.domain_name
  ips                = []
  automatic_security = true
  custom_spf         = true
  valid              = true
}

resource "sendgrid_api_key" "default" {
  name   = "${var.app_name}-send"
  scopes = ["mail.send"]
}