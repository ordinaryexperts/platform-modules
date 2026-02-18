# modules/ecr-repository/tests/basic.tftest.hcl
#
# Integration tests for the ecr-repository module.

provider "aws" {
  region = "us-east-1"
}

run "setup" {
  module {
    source = "./tests/fixtures"
  }
}

run "creates_repository_with_defaults" {
  command = apply

  variables {
    name              = "platform-test/${run.setup.test_id}"
    organization_path = run.setup.organization_path
  }

  # Repository exists
  assert {
    condition     = aws_ecr_repository.this.name == "platform-test/${run.setup.test_id}"
    error_message = "Repository name should match input"
  }

  # Scan on push enabled by default
  assert {
    condition     = aws_ecr_repository.this.image_scanning_configuration[0].scan_on_push == true
    error_message = "Scan on push should be enabled by default"
  }

  # Default encryption
  assert {
    condition     = aws_ecr_repository.this.encryption_configuration[0].encryption_type == "AES256"
    error_message = "Should use AES256 encryption by default"
  }

  # Cross-account policy created
  assert {
    condition     = length(aws_ecr_repository_policy.cross_account) == 1
    error_message = "Cross-account policy should be created when organization_path is set"
  }

  # Lifecycle policy created by default
  assert {
    condition     = length(aws_ecr_lifecycle_policy.this) == 1
    error_message = "Lifecycle policy should be created by default"
  }
}

run "creates_repository_immutable_tags" {
  command = apply

  variables {
    name                 = "platform-test/immutable-${run.setup.test_id}"
    image_tag_mutability = "IMMUTABLE"
  }

  assert {
    condition     = aws_ecr_repository.this.image_tag_mutability == "IMMUTABLE"
    error_message = "Tag mutability should be IMMUTABLE"
  }
}
