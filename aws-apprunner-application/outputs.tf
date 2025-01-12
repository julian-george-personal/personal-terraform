output "cname_records" {
value = toset([for obj in aws_apprunner_custom_domain_association.apprunner-domain-name.certificate_validation_records : obj.value])
}