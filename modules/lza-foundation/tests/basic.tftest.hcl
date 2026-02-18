# modules/lza-foundation/tests/basic.tftest.hcl
#
# Validation tests for the lza-foundation module.
# Uses `command = plan` only - actual deployment takes 60-90 minutes.

provider "aws" {
  region = "us-east-1"
}

run "setup" {
  module {
    source = "./tests/fixtures"
  }
}

run "validates_configuration" {
  command = plan

  variables {
    management_account_email  = "mgmt@example.com"
    log_archive_account_email = "logs@example.com"
    audit_account_email       = "audit@example.com"
    github_oidc_provider_arn  = run.setup.github_oidc_provider_arn
    accelerator_prefix        = "test"
  }

  # Plan should succeed with valid inputs
  assert {
    condition     = aws_cloudformation_stack.lza_installer.name == "AWSAccelerator-Installer"
    error_message = "CloudFormation stack name should be correct"
  }

  assert {
    condition     = aws_iam_role.platform_lza_access.name == "test-PlatformLzaAccess"
    error_message = "IAM role name should include accelerator prefix"
  }
}

run "rejects_invalid_email" {
  command = plan

  variables {
    management_account_email  = "not-an-email"
    log_archive_account_email = "logs@example.com"
    audit_account_email       = "audit@example.com"
    github_oidc_provider_arn  = run.setup.github_oidc_provider_arn
  }

  expect_failures = [var.management_account_email]
}

run "rejects_invalid_prefix" {
  command = plan

  variables {
    management_account_email  = "mgmt@example.com"
    log_archive_account_email = "logs@example.com"
    audit_account_email       = "audit@example.com"
    github_oidc_provider_arn  = run.setup.github_oidc_provider_arn
    accelerator_prefix        = "Invalid-Prefix"
  }

  expect_failures = [var.accelerator_prefix]
}
