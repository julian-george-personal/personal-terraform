
resource "aws_apprunner_custom_domain_association" "apprunner-domain-name" {
  domain_name = var.domain_name
  service_arn = var.apprunner_arn
}

data "aws_apprunner_hosted_zone_id" "apprunner-hosted-zone-id" {}

resource "aws_route53_record" "apprunner-alias-record" {
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_apprunner_custom_domain_association.apprunner-domain-name.dns_target
    zone_id                = data.aws_apprunner_hosted_zone_id.apprunner-hosted-zone-id.id
    evaluate_target_health = true
  }
}
resource "aws_route53_record" "apprunner-cname-record" {
  for_each = {
    for idx in range(3) : idx => tolist(aws_apprunner_custom_domain_association.apprunner-domain-name.certificate_validation_records)[idx]
  }
  zone_id = var.hosted_zone_id
  name    = each.value.name
  ttl     = 10800
  records = [each.value.value]
  type    = "CNAME"
}