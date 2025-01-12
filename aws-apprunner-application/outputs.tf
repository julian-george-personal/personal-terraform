output "cname_records" {
value = [for obj in aws_apprunner_custom_domain_association.apprunner-domain-name.certificate_validation_records : obj.value]
}