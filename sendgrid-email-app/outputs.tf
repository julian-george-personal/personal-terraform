output "api_key_value" {
  value = sendgrid_api_key.default.api_key
}

output "dns_records" {
  value = sendgrid_domain_authentication.default.dns
}