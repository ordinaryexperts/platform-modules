# modules/static-website/tests/basic.tftest.hcl
#
# Integration tests for the static-website module.
# Note: CloudFront distribution creation takes 10-15 minutes.

provider "aws" {
  region = "us-east-1"
}

run "setup" {
  module {
    source = "./tests/fixtures"
  }
}

run "creates_website_with_cloudfront" {
  command = apply

  variables {
    name            = "platform-test"
    environment     = run.setup.test_id
    domain          = "test-${run.setup.test_id}.${run.setup.test_domain}"
    certificate_arn = run.setup.certificate_arn
  }

  # S3 bucket created
  assert {
    condition     = aws_s3_bucket.website.id == "platform-test-${run.setup.test_id}-website"
    error_message = "Website bucket name should follow naming convention"
  }

  # Bucket versioning enabled
  assert {
    condition     = aws_s3_bucket_versioning.website.versioning_configuration[0].status == "Enabled"
    error_message = "Versioning should be enabled"
  }

  # Public access blocked
  assert {
    condition     = aws_s3_bucket_public_access_block.website.block_public_acls == true
    error_message = "Public access should be blocked"
  }

  # CloudFront distribution created
  assert {
    condition     = aws_cloudfront_distribution.website.enabled == true
    error_message = "CloudFront distribution should be enabled"
  }

  # HTTPS redirect configured
  assert {
    condition     = aws_cloudfront_distribution.website.default_cache_behavior[0].viewer_protocol_policy == "redirect-to-https"
    error_message = "Should redirect HTTP to HTTPS"
  }

  # OAC configured
  assert {
    condition     = length(aws_cloudfront_origin_access_control.website.id) > 0
    error_message = "Origin Access Control should be configured"
  }

  # SSM parameters created
  assert {
    condition     = aws_ssm_parameter.distribution_id.value == aws_cloudfront_distribution.website.id
    error_message = "SSM parameter should contain distribution ID"
  }
}
