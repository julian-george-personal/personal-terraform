resource "aws_route53_record" "personal-mail" {
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "MX"
  ttl     = 172800
  records = ["1 aspmx.l.google.com", "5 alt1.aspmx.l.google.com", "5 alt2.aspmx.l.google.com", "10 alt3.aspmx.l.google.com", "10 alt4.aspmx.l.google.com"]
}

resource "aws_secretsmanager_secret" "dkim_secret" {
  name = "dkim-record-${var.domain_name}"
}

data "aws_secretsmanager_secret_version" "dkim_secret_latest" {
  secret_id = aws_secretsmanager_secret.dkim_secret.id
}

resource "aws_route53_record" "dkim_record" {
  zone_id = var.hosted_zone_id
  name    = "google._domainkey.${var.domain_name}"
  type    = "TXT"
  ttl     = 3600
  records = [data.aws_secretsmanager_secret_version.dkim_secret_latest.secret_string]
}

resource "aws_route53_record" "spf_record" {
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "TXT"
  ttl     = 3600
  records = ["v=spf1 include:_spf.google.com ~all"]
}