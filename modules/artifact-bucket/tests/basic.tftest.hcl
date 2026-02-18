# modules/artifact-bucket/tests/basic.tftest.hcl
#
# Integration tests for the artifact-bucket module.
# Requires test fixtures deployed to platform-dev.

provider "aws" {
  region = "us-east-1"
}

# Read organization path from SSM (set by test fixtures)
run "setup" {
  module {
    source = "./tests/fixtures"
  }
}

run "creates_bucket_with_defaults" {
  command = apply

  variables {
    bucket_name       = "platform-test-artifacts-${run.setup.test_id}"
    organization_path = run.setup.organization_path
    force_destroy     = true
  }

  # Bucket exists
  assert {
    condition     = aws_s3_bucket.artifacts.id == "platform-test-artifacts-${run.setup.test_id}"
    error_message = "Bucket name should match input"
  }

  # Versioning enabled by default
  assert {
    condition     = aws_s3_bucket_versioning.artifacts.versioning_configuration[0].status == "Enabled"
    error_message = "Versioning should be enabled by default"
  }

  # Public access blocked
  assert {
    condition     = aws_s3_bucket_public_access_block.artifacts.block_public_acls == true
    error_message = "Public ACLs should be blocked"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.artifacts.block_public_policy == true
    error_message = "Public policies should be blocked"
  }

  # Encryption configured
  assert {
    condition     = aws_s3_bucket_server_side_encryption_configuration.artifacts.rule[0].apply_server_side_encryption_by_default[0].sse_algorithm == "AES256"
    error_message = "Bucket should use AES256 encryption"
  }

  # Cross-account policy created (org path was provided)
  assert {
    condition     = length(aws_s3_bucket_policy.cross_account) == 1
    error_message = "Cross-account policy should be created when organization_path is set"
  }

  # Lifecycle policy created by default
  assert {
    condition     = length(aws_s3_bucket_lifecycle_configuration.artifacts) == 1
    error_message = "Lifecycle policy should be created by default"
  }
}

run "creates_bucket_without_org_path" {
  command = apply

  variables {
    bucket_name   = "platform-test-artifacts-no-org-${run.setup.test_id}"
    force_destroy = true
  }

  # Cross-account policy NOT created (no org path)
  assert {
    condition     = length(aws_s3_bucket_policy.cross_account) == 0
    error_message = "Cross-account policy should not be created without organization_path"
  }
}
