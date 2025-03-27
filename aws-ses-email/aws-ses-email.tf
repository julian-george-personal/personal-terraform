resource "aws_ses_domain_identity" "ses-identity" {
  domain = var.domain_name
}

resource "aws_route53_record" "ses_verification" {
  zone_id = var.hosted_zone_id
  name    = "_amazonses.${var.domain_name}"
  type    = "TXT"
  ttl     = 1800

  records = [aws_ses_domain_identity.ses-identity.verification_token]
}

resource "aws_ses_domain_dkim" "ses-dkim" {
  domain = var.domain_name
}

resource "aws_route53_record" "dkim_records" {
  for_each = {
    for idx in range(3) : idx => tolist(aws_ses_domain_dkim.ses-dkim.dkim_tokens)[idx]
  }

  zone_id = var.hosted_zone_id
  name    = "${each.value}._domainkey.${var.domain_name}"
  type    = "CNAME"
  ttl     = 1800
  records = ["${each.value}.dkim.amazonses.com"]
}

resource "aws_ses_domain_identity_verification" "ses-email" {
  domain = var.domain_name
}

data "aws_iam_policy_document" "ses-policy" {
  statement {
    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail"
    ]
    resources = [
      aws_ses_domain_identity.ses-identity.arn
    ]
    effect = "Allow"
  }
}

resource "aws_iam_role_policy" "ses-policy" {
  count  = var.email_sender_role != null ? 1 : 0
  name   = "${var.app_name}-ses-sendemail"
  role   = var.email_sender_role
  policy = data.aws_iam_policy_document.ses-policy.json
}

resource "aws_route53_record" "ses_spf" {
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "TXT"
  ttl     = 1800
  records = [
    "v=spf1 include:amazonses.com ~all"
  ]
}

