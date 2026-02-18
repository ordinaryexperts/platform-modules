# Static Website Module

Creates an S3-backed static website with CloudFront distribution. Designed for use with OE Platform's S3 artifact deployment workflow.

## Features

- Private S3 bucket for website content (no public access)
- CloudFront distribution with HTTPS and custom domain
- Origin Access Control (OAC) for secure S3 access
- SPA-friendly error handling (configurable)
- SSM parameters for Platform integration
- Optional WAF integration
- Optional CloudFront access logging

## Usage

```hcl
module "website" {
  source = "github.com/org/platform-modules//modules/static-website?ref=static-website-v1.0.0"

  name            = "web-app"
  environment     = "prod1"
  domain          = "www.example.com"
  certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abc123"

  tags = {
    Project = "web-app"
    Owner   = "platform"
  }
}

# Route53 DNS record (if using Route53)
resource "aws_route53_record" "website" {
  zone_id = aws_route53_zone.main.zone_id
  name    = module.website.dns_record.name
  type    = module.website.dns_record.type

  alias {
    name                   = module.website.dns_record.alias.name
    zone_id                = module.website.dns_record.alias.zone_id
    evaluate_target_health = module.website.dns_record.alias.evaluate_target_health
  }
}
```

## Platform Integration

This module creates SSM parameters used by the Platform's deploy workflow:

| Parameter | Purpose |
|-----------|---------|
| `/{name}/{environment}/cloudfront-distribution-id` | Used for cache invalidation |
| `/{name}/{environment}/website-bucket-name` | Target bucket for artifact sync |
| `/{name}/{environment}/artifact-key` | Tracks current deployed artifact |

The deploy workflow:
1. Syncs artifacts from the SharedServices artifact bucket to the website bucket
2. Updates the artifact-key SSM parameter
3. Invalidates the CloudFront distribution
4. Reports completion to Platform

## Requirements

- ACM certificate must be in `us-east-1` (CloudFront requirement)
- Domain must be configured to point to the CloudFront distribution

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name for the website resources | `string` | n/a | yes |
| environment | Environment name | `string` | n/a | yes |
| domain | Domain name for the website | `string` | n/a | yes |
| certificate_arn | ACM certificate ARN (must be in us-east-1) | `string` | n/a | yes |
| artifact_bucket_arn | ARN of artifact bucket in SharedServices | `string` | `null` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |
| waf_acl_arn | WAF Web ACL ARN | `string` | `null` | no |
| price_class | CloudFront price class | `string` | `"PriceClass_100"` | no |
| custom_error_responses | Custom error responses for SPA | `list(object)` | SPA defaults | no |
| default_root_object | Default root object | `string` | `"index.html"` | no |
| enable_logging | Enable CloudFront logging | `bool` | `false` | no |
| logging_bucket | S3 bucket for logs | `string` | `null` | no |
| logging_prefix | Prefix for logs | `string` | `"cloudfront/"` | no |
| minimum_protocol_version | Minimum TLS version | `string` | `"TLSv1.2_2021"` | no |

## Outputs

| Name | Description |
|------|-------------|
| website_bucket_name | S3 bucket name |
| website_bucket_arn | S3 bucket ARN |
| cloudfront_distribution_id | CloudFront distribution ID |
| cloudfront_distribution_arn | CloudFront distribution ARN |
| cloudfront_domain_name | CloudFront domain name |
| cloudfront_hosted_zone_id | CloudFront hosted zone ID |
| ssm_distribution_id_param | SSM parameter name for distribution ID |
| ssm_website_bucket_param | SSM parameter name for bucket name |
| ssm_artifact_key_param | SSM parameter name for artifact key |
| dns_record | DNS record configuration for Route53 |

## SPA Support

By default, the module is configured for Single Page Applications (SPAs) like React, Vue, or Angular. It returns `index.html` for 404 and 403 errors, allowing client-side routing to work.

To disable SPA support:

```hcl
module "website" {
  # ...
  custom_error_responses = []
}
```

## Security

- S3 bucket is completely private (no public access)
- Access only via CloudFront using Origin Access Control (OAC)
- HTTPS enforced (HTTP redirects to HTTPS)
- TLS 1.2+ required
- Optional WAF integration for additional protection
