terraform {
  required_providers {
    resend = {
      source = "jhoward321/resend"
    }
  }
}

resource "resend_domain" "default" {
  name   = var.domain_name
  region = "us-east-1"
}

resource "resend_api_key" "default" {
  name       = "${var.app_name}-send"
  permission = "sending_access"
  domain_id  = resend_domain.default.id
}
