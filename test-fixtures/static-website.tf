# test-fixtures/static-website.tf
#
# Test fixtures for the static-website module:
# - ACM certificate with DNS validation
# - Route53 hosted zone data lookup

data "aws_route53_zone" "test" {
  name = var.test_domain
}

# ACM certificate for CloudFront (must be in us-east-1)
resource "aws_acm_certificate" "test" {
  domain_name       = "*.${var.test_domain}"
  validation_method = "DNS"

  subject_alternative_names = [var.test_domain]

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name = "platform-modules-test-cert"
  })
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.test.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.test.zone_id
}

resource "aws_acm_certificate_validation" "test" {
  certificate_arn         = aws_acm_certificate.test.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# Store in SSM for test consumption
resource "aws_ssm_parameter" "certificate_arn" {
  name        = "/platform-test/static-website/certificate-arn"
  description = "ACM certificate ARN for static-website module tests"
  type        = "String"
  value       = aws_acm_certificate.test.arn

  tags = var.tags
}

resource "aws_ssm_parameter" "test_domain" {
  name        = "/platform-test/static-website/test-domain"
  description = "Test domain for static-website module tests"
  type        = "String"
  value       = var.test_domain

  tags = var.tags
}

resource "aws_ssm_parameter" "hosted_zone_id" {
  name        = "/platform-test/static-website/hosted-zone-id"
  description = "Route53 hosted zone ID for test domain"
  type        = "String"
  value       = data.aws_route53_zone.test.zone_id

  tags = var.tags
}
