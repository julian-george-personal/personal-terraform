terraform {
  required_providers {
    sendgrid = {
      source = "indentinc/sendgrid"
    }
  }
}

resource "sendgrid_template" "default" {
  name       = var.template_name
  generation = "dynamic"
}

resource "sendgrid_template_version" "default" {
  name                   = var.template_name
  template_id            = sendgrid_template.default.id
  active                 = 1
  html_content           = var.email_body
  generate_plain_content = true
  subject                = var.email_subject
}