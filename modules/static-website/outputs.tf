output "website_bucket_name" {
  description = "Name of the S3 bucket for website content"
  value       = aws_s3_bucket.website.id
}

output "website_bucket_arn" {
  description = "ARN of the S3 bucket for website content"
  value       = aws_s3_bucket.website.arn
}

output "website_bucket_domain_name" {
  description = "Regional domain name of the S3 bucket"
  value       = aws_s3_bucket.website.bucket_regional_domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.website.id
}

output "cloudfront_distribution_arn" {
  description = "CloudFront distribution ARN"
  value       = aws_cloudfront_distribution.website.arn
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.website.domain_name
}

output "cloudfront_hosted_zone_id" {
  description = "CloudFront distribution hosted zone ID (for Route53 alias records)"
  value       = aws_cloudfront_distribution.website.hosted_zone_id
}

output "ssm_distribution_id_param" {
  description = "SSM parameter name containing the CloudFront distribution ID"
  value       = aws_ssm_parameter.distribution_id.name
}

output "ssm_website_bucket_param" {
  description = "SSM parameter name containing the website bucket name"
  value       = aws_ssm_parameter.website_bucket.name
}

output "ssm_artifact_key_param" {
  description = "SSM parameter name containing the current artifact key"
  value       = aws_ssm_parameter.artifact_key.name
}

# For DNS configuration
output "dns_record" {
  description = "DNS record configuration for Route53 alias"
  value = {
    name = var.domain
    type = "A"
    alias = {
      name                   = aws_cloudfront_distribution.website.domain_name
      zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
      evaluate_target_health = false
    }
  }
}
