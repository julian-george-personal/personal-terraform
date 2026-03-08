output "api_key_token" {
  value     = resend_api_key.default.token
  sensitive = true
}

output "dkim_records" {
  value = resend_domain.default.dkim_records
}

output "spf_mx_record" {
  value = resend_domain.default.spf_mx_record
}

output "spf_txt_record" {
  value = resend_domain.default.spf_txt_record
}
