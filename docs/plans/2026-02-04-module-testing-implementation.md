# Module Testing Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add OpenTofu test infrastructure with shared fixtures in platform-dev and CI workflow for validation and integration testing.

**Architecture:** Test fixtures deploy once to platform-dev, storing outputs in SSM parameters. Each module has a `tests/` directory with `.tftest.hcl` files that read fixture values from SSM. CI runs validation on all modules and integration tests only on changed modules.

**Tech Stack:** OpenTofu 1.6+, GitHub Actions, AWS (SSM, ACM, Route53, IAM)

---

## Prerequisites

Before starting, ensure:
- AWS CLI configured with access to platform-dev account
- OpenTofu 1.6+ installed locally
- A test domain available in Route53 (for static-website certificate)

---

### Task 1: Create Test Fixtures - Base Files

**Files:**
- Create: `test-fixtures/versions.tf`
- Create: `test-fixtures/main.tf`
- Create: `test-fixtures/variables.tf`
- Create: `test-fixtures/outputs.tf`

**Step 1: Create versions.tf**

```hcl
# test-fixtures/versions.tf
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  backend "s3" {
    bucket = "oe-platform-dev-terraform-state"
    key    = "platform-modules/test-fixtures/terraform.tfstate"
    region = "us-east-1"
  }
}
```

**Step 2: Create main.tf**

```hcl
# test-fixtures/main.tf
#
# Shared test fixtures for platform-modules integration tests.
# Deploy once to platform-dev, outputs stored in SSM for test consumption.

provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
```

**Step 3: Create variables.tf**

```hcl
# test-fixtures/variables.tf

variable "test_domain" {
  description = "Domain name for test resources (must have Route53 hosted zone)"
  type        = string
}

variable "organization_path" {
  description = "AWS Organizations path for cross-account tests"
  type        = string
}

variable "tags" {
  description = "Tags for all test fixture resources"
  type        = map(string)
  default = {
    Purpose   = "platform-modules-testing"
    ManagedBy = "tofu"
  }
}
```

**Step 4: Create outputs.tf**

```hcl
# test-fixtures/outputs.tf
# Outputs are also stored in SSM for test consumption

output "certificate_arn" {
  description = "ACM certificate ARN for static-website tests"
  value       = aws_acm_certificate.test.arn
}

output "organization_path" {
  description = "Organization path for cross-account tests"
  value       = var.organization_path
}

output "github_oidc_provider_arn" {
  description = "GitHub OIDC provider ARN for lza-foundation tests"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "test_role_arn" {
  description = "IAM role ARN for CI test runs"
  value       = aws_iam_role.ci_test.arn
}
```

**Step 5: Verify syntax**

Run: `tofu -chdir=test-fixtures fmt`
Run: `tofu -chdir=test-fixtures init -backend=false && tofu -chdir=test-fixtures validate`

Expected: Success (may show warnings about missing referenced resources - that's OK, we'll add them next)

---

### Task 2: Create Test Fixtures - Static Website Resources

**Files:**
- Create: `test-fixtures/static-website.tf`

**Step 1: Create static-website.tf**

```hcl
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
```

**Step 2: Verify syntax**

Run: `tofu -chdir=test-fixtures fmt && tofu -chdir=test-fixtures validate`

Expected: Validation successful

---

### Task 3: Create Test Fixtures - Shared Resources

**Files:**
- Create: `test-fixtures/artifact-bucket.tf`
- Create: `test-fixtures/ecr-repository.tf`
- Create: `test-fixtures/lza-foundation.tf`

**Step 1: Create artifact-bucket.tf**

```hcl
# test-fixtures/artifact-bucket.tf
#
# Test fixtures for the artifact-bucket module:
# - Organization path stored in SSM

resource "aws_ssm_parameter" "organization_path" {
  name        = "/platform-test/organization-path"
  description = "AWS Organizations path for cross-account policy tests"
  type        = "String"
  value       = var.organization_path

  tags = var.tags
}
```

**Step 2: Create ecr-repository.tf**

```hcl
# test-fixtures/ecr-repository.tf
#
# Test fixtures for the ecr-repository module:
# - Uses same organization path as artifact-bucket (already in SSM)
# - No additional resources needed
```

**Step 3: Create lza-foundation.tf**

```hcl
# test-fixtures/lza-foundation.tf
#
# Test fixtures for the lza-foundation module:
# - GitHub OIDC provider for role trust

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  # GitHub's OIDC thumbprint
  thumbprint_list = ["ffffffffffffffffffffffffffffffffffffffff"]

  tags = merge(var.tags, {
    Name = "github-actions-oidc"
  })
}

resource "aws_ssm_parameter" "github_oidc_provider_arn" {
  name        = "/platform-test/lza-foundation/github-oidc-provider-arn"
  description = "GitHub OIDC provider ARN for lza-foundation tests"
  type        = "String"
  value       = aws_iam_openid_connect_provider.github.arn

  tags = var.tags
}
```

**Step 4: Verify syntax**

Run: `tofu -chdir=test-fixtures fmt && tofu -chdir=test-fixtures validate`

Expected: Validation successful

---

### Task 4: Create Test Fixtures - CI IAM Role

**Files:**
- Modify: `test-fixtures/lza-foundation.tf` (add CI role)

**Step 1: Add CI test role to lza-foundation.tf**

Append to `test-fixtures/lza-foundation.tf`:

```hcl
# IAM role for CI test runs (GitHub Actions OIDC)
resource "aws_iam_role" "ci_test" {
  name        = "platform-modules-ci-test"
  description = "Role for platform-modules CI integration tests"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:ordinaryexperts/platform-modules:*"
          }
        }
      }
    ]
  })

  tags = var.tags
}

# Policy granting permissions needed for module tests
resource "aws_iam_role_policy" "ci_test" {
  name = "test-permissions"
  role = aws_iam_role.ci_test.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SSMReadTestFixtures"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/platform-test/*"
      },
      {
        Sid    = "S3TestBuckets"
        Effect = "Allow"
        Action = [
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:GetBucket*",
          "s3:PutBucket*",
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::platform-test-*",
          "arn:aws:s3:::platform-test-*/*"
        ]
      },
      {
        Sid    = "ECRTestRepositories"
        Effect = "Allow"
        Action = [
          "ecr:CreateRepository",
          "ecr:DeleteRepository",
          "ecr:DescribeRepositories",
          "ecr:GetRepositoryPolicy",
          "ecr:SetRepositoryPolicy",
          "ecr:DeleteRepositoryPolicy",
          "ecr:PutLifecyclePolicy",
          "ecr:GetLifecyclePolicy",
          "ecr:DeleteLifecyclePolicy",
          "ecr:TagResource",
          "ecr:ListTagsForResource"
        ]
        Resource = "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/platform-test/*"
      },
      {
        Sid    = "CloudFrontTestDistributions"
        Effect = "Allow"
        Action = [
          "cloudfront:CreateDistribution",
          "cloudfront:DeleteDistribution",
          "cloudfront:GetDistribution",
          "cloudfront:UpdateDistribution",
          "cloudfront:TagResource",
          "cloudfront:CreateOriginAccessControl",
          "cloudfront:DeleteOriginAccessControl",
          "cloudfront:GetOriginAccessControl",
          "cloudfront:ListTagsForResource"
        ]
        Resource = "*"
      },
      {
        Sid    = "SSMTestParameters"
        Effect = "Allow"
        Action = [
          "ssm:PutParameter",
          "ssm:DeleteParameter",
          "ssm:GetParameter",
          "ssm:AddTagsToResource",
          "ssm:ListTagsForResource"
        ]
        Resource = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/platform-test-*"
      },
      {
        Sid    = "Route53TestRecords"
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:GetChange"
        ]
        Resource = [
          "arn:aws:route53:::hostedzone/*",
          "arn:aws:route53:::change/*"
        ]
      },
      {
        Sid    = "Route53ListZones"
        Effect = "Allow"
        Action = [
          "route53:ListHostedZones",
          "route53:GetHostedZone",
          "route53:ListResourceRecordSets"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_ssm_parameter" "ci_test_role_arn" {
  name        = "/platform-test/ci-role-arn"
  description = "IAM role ARN for CI integration tests"
  type        = "String"
  value       = aws_iam_role.ci_test.arn

  tags = var.tags
}
```

**Step 2: Verify syntax**

Run: `tofu -chdir=test-fixtures fmt && tofu -chdir=test-fixtures validate`

Expected: Validation successful

---

### Task 5: Create artifact-bucket Test

**Files:**
- Create: `modules/artifact-bucket/tests/basic.tftest.hcl`

**Step 1: Create test file**

```hcl
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
```

**Step 2: Create test helper module**

```hcl
# modules/artifact-bucket/tests/fixtures/main.tf
#
# Helper module to read test fixtures from SSM

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

data "aws_ssm_parameter" "organization_path" {
  name = "/platform-test/organization-path"
}

resource "random_id" "test" {
  byte_length = 4
}

output "organization_path" {
  value = data.aws_ssm_parameter.organization_path.value
}

output "test_id" {
  value = random_id.test.hex
}
```

**Step 3: Create fixtures versions.tf**

```hcl
# modules/artifact-bucket/tests/fixtures/versions.tf
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}
```

**Step 4: Verify syntax**

Run: `tofu -chdir=modules/artifact-bucket fmt -recursive`

Expected: Files formatted (or no changes if already formatted)

---

### Task 6: Create ecr-repository Test

**Files:**
- Create: `modules/ecr-repository/tests/basic.tftest.hcl`
- Create: `modules/ecr-repository/tests/fixtures/main.tf`
- Create: `modules/ecr-repository/tests/fixtures/versions.tf`

**Step 1: Create test file**

```hcl
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
```

**Step 2: Create test fixtures**

```hcl
# modules/ecr-repository/tests/fixtures/main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

data "aws_ssm_parameter" "organization_path" {
  name = "/platform-test/organization-path"
}

resource "random_id" "test" {
  byte_length = 4
}

output "organization_path" {
  value = data.aws_ssm_parameter.organization_path.value
}

output "test_id" {
  value = random_id.test.hex
}
```

```hcl
# modules/ecr-repository/tests/fixtures/versions.tf
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}
```

**Step 3: Verify syntax**

Run: `tofu -chdir=modules/ecr-repository fmt -recursive`

Expected: Files formatted

---

### Task 7: Create static-website Test

**Files:**
- Create: `modules/static-website/tests/basic.tftest.hcl`
- Create: `modules/static-website/tests/fixtures/main.tf`
- Create: `modules/static-website/tests/fixtures/versions.tf`

**Step 1: Create test file**

```hcl
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
```

**Step 2: Create test fixtures**

```hcl
# modules/static-website/tests/fixtures/main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

data "aws_ssm_parameter" "certificate_arn" {
  name = "/platform-test/static-website/certificate-arn"
}

data "aws_ssm_parameter" "test_domain" {
  name = "/platform-test/static-website/test-domain"
}

resource "random_id" "test" {
  byte_length = 4
}

output "certificate_arn" {
  value = data.aws_ssm_parameter.certificate_arn.value
}

output "test_domain" {
  value = data.aws_ssm_parameter.test_domain.value
}

output "test_id" {
  value = random_id.test.hex
}
```

```hcl
# modules/static-website/tests/fixtures/versions.tf
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}
```

**Step 3: Verify syntax**

Run: `tofu -chdir=modules/static-website fmt -recursive`

Expected: Files formatted

---

### Task 8: Create lza-foundation Test (Validation Only)

**Files:**
- Create: `modules/lza-foundation/tests/basic.tftest.hcl`
- Create: `modules/lza-foundation/tests/fixtures/main.tf`
- Create: `modules/lza-foundation/tests/fixtures/versions.tf`

**Step 1: Create test file (plan only, no apply)**

```hcl
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
```

**Step 2: Create test fixtures**

```hcl
# modules/lza-foundation/tests/fixtures/main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

data "aws_ssm_parameter" "github_oidc_provider_arn" {
  name = "/platform-test/lza-foundation/github-oidc-provider-arn"
}

output "github_oidc_provider_arn" {
  value = data.aws_ssm_parameter.github_oidc_provider_arn.value
}
```

```hcl
# modules/lza-foundation/tests/fixtures/versions.tf
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
```

**Step 3: Verify syntax**

Run: `tofu -chdir=modules/lza-foundation fmt -recursive`

Expected: Files formatted

---

### Task 9: Create Change Detection Script

**Files:**
- Create: `scripts/detect-changed-modules.sh`

**Step 1: Create script**

```bash
#!/usr/bin/env bash
# scripts/detect-changed-modules.sh
#
# Detects which modules have changed in a PR and outputs JSON for GitHub Actions matrix.
# Skips lza-foundation (validation-only, too slow for integration tests).

set -euo pipefail

BASE_REF="${GITHUB_BASE_REF:-main}"

# Get list of changed files compared to base branch
changed_files=$(git diff --name-only "origin/$BASE_REF"...HEAD 2>/dev/null || git diff --name-only HEAD~1)

# Extract unique module names from changed paths
declare -A modules_map
while IFS= read -r file; do
  if [[ "$file" =~ ^modules/([^/]+)/ ]]; then
    module="${BASH_REMATCH[1]}"
    # Skip lza-foundation (validation-only due to 60-90min deploy time)
    if [[ "$module" != "lza-foundation" ]]; then
      modules_map["$module"]=1
    fi
  fi
done <<< "$changed_files"

# Convert to array
modules=("${!modules_map[@]}")

# Output for GitHub Actions
if [[ ${#modules[@]} -eq 0 ]]; then
  echo "modules=[]" >> "$GITHUB_OUTPUT"
  echo "has_changes=false" >> "$GITHUB_OUTPUT"
  echo "No module changes detected"
else
  # Sort for consistent ordering
  IFS=$'\n' sorted=($(sort <<< "${modules[*]}")); unset IFS
  json=$(printf '%s\n' "${sorted[@]}" | jq -R . | jq -s -c .)
  echo "modules=$json" >> "$GITHUB_OUTPUT"
  echo "has_changes=true" >> "$GITHUB_OUTPUT"
  echo "Changed modules: ${sorted[*]}"
fi
```

**Step 2: Make executable**

Run: `chmod +x scripts/detect-changed-modules.sh`

---

### Task 10: Create CI Workflow

**Files:**
- Create: `.github/workflows/test.yml`

**Step 1: Create workflow file**

```yaml
# .github/workflows/test.yml
#
# Runs validation on all modules and integration tests on changed modules.

name: Test Modules

on:
  pull_request:
    branches: [main]
  workflow_dispatch:
    inputs:
      module:
        description: 'Specific module to test (leave empty for changed modules only)'
        required: false
        type: string

concurrency:
  group: test-${{ github.head_ref || github.ref }}
  cancel-in-progress: true

jobs:
  detect-changes:
    runs-on: ubuntu-latest
    outputs:
      modules: ${{ steps.changes.outputs.modules }}
      has_changes: ${{ steps.changes.outputs.has_changes }}
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Detect changed modules
        id: changes
        run: |
          if [[ -n "${{ inputs.module }}" ]]; then
            echo "modules=[\"${{ inputs.module }}\"]" >> "$GITHUB_OUTPUT"
            echo "has_changes=true" >> "$GITHUB_OUTPUT"
          else
            ./scripts/detect-changed-modules.sh
          fi

  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup OpenTofu
        uses: opentofu/setup-opentofu@v1
        with:
          tofu_version: 1.6.0

      - name: Check formatting
        run: tofu fmt -check -recursive

      - name: Validate all modules
        run: |
          for dir in modules/*/; do
            module=$(basename "$dir")
            echo "::group::Validating $module"
            tofu -chdir="$dir" init -backend=false
            tofu -chdir="$dir" validate
            echo "::endgroup::"
          done

  integration:
    needs: [detect-changes, validate]
    if: needs.detect-changes.outputs.has_changes == 'true'
    runs-on: ubuntu-latest
    strategy:
      matrix:
        module: ${{ fromJson(needs.detect-changes.outputs.modules) }}
      fail-fast: false
    permissions:
      id-token: write
      contents: read

    steps:
      - uses: actions/checkout@v4

      - name: Setup OpenTofu
        uses: opentofu/setup-opentofu@v1
        with:
          tofu_version: 1.6.0

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_TEST_ROLE_ARN }}
          aws-region: us-east-1

      - name: Run integration tests
        run: |
          echo "::group::Testing ${{ matrix.module }}"
          cd modules/${{ matrix.module }}
          tofu init
          tofu test -verbose
          echo "::endgroup::"

  # Always run lza-foundation validation (plan only, no apply)
  validate-lza:
    needs: [detect-changes, validate]
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read

    steps:
      - uses: actions/checkout@v4

      - name: Setup OpenTofu
        uses: opentofu/setup-opentofu@v1
        with:
          tofu_version: 1.6.0

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_TEST_ROLE_ARN }}
          aws-region: us-east-1

      - name: Run lza-foundation validation tests
        run: |
          cd modules/lza-foundation
          tofu init
          tofu test -verbose
```

**Step 2: Verify YAML syntax**

Run: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/test.yml'))"`

Expected: No output (valid YAML)

---

### Task 11: Deploy Test Fixtures to Platform-Dev

**Prerequisites:**
- AWS CLI configured with admin access to platform-dev
- Test domain with Route53 hosted zone
- Know your organization path

**Step 1: Create terraform.tfvars**

```hcl
# test-fixtures/terraform.tfvars
test_domain       = "test.example.com"  # Replace with actual test domain
organization_path = "o-xxx/r-xxx/ou-xxx" # Replace with actual org path
```

**Step 2: Initialize and plan**

Run: `cd test-fixtures && tofu init`
Run: `tofu plan -out=tfplan`

Review the plan output.

**Step 3: Apply**

Run: `tofu apply tfplan`

Expected: Resources created, SSM parameters populated.

**Step 4: Verify SSM parameters**

Run: `aws ssm get-parameters-by-path --path /platform-test/ --recursive --query 'Parameters[*].Name'`

Expected: List of parameter names under /platform-test/

---

### Task 12: Add Repository Secret and Test Locally

**Step 1: Get CI role ARN from SSM**

Run: `aws ssm get-parameter --name /platform-test/ci-role-arn --query 'Parameter.Value' --output text`

**Step 2: Add GitHub secret**

In repository settings, add secret:
- Name: `AWS_TEST_ROLE_ARN`
- Value: (the ARN from step 1)

**Step 3: Test locally (artifact-bucket)**

Run: `cd modules/artifact-bucket && tofu init && tofu test -verbose`

Expected: Tests pass

**Step 4: Test locally (ecr-repository)**

Run: `cd modules/ecr-repository && tofu init && tofu test -verbose`

Expected: Tests pass

---

### Task 13: Update CLAUDE.md with Testing Instructions

**Files:**
- Modify: `CLAUDE.md`

**Step 1: Add testing section to CLAUDE.md**

Add after the "Validation Commands" section:

```markdown
## Testing

### Running Tests Locally

Before committing module changes, run integration tests:

```bash
cd modules/<module-name>
tofu init
tofu test -verbose
```

### Test Structure

Each module has a `tests/` directory with:
- `basic.tftest.hcl` - Integration tests
- `fixtures/` - Helper module to read test fixtures from SSM

### Test Fixtures

Shared test resources are deployed to platform-dev and stored in SSM under `/platform-test/`:
- `/platform-test/organization-path` - AWS Organizations path
- `/platform-test/static-website/certificate-arn` - ACM certificate
- `/platform-test/lza-foundation/github-oidc-provider-arn` - GitHub OIDC provider

To update fixtures: `cd test-fixtures && tofu apply`

### CI Behavior

- **Validation**: Runs on all modules (format check + validate)
- **Integration**: Runs only on changed modules
- **lza-foundation**: Validation only (plan, no apply) due to 60-90min deploy time
```

---

## Summary

| Task | Description |
|------|-------------|
| 1 | Create test-fixtures base files (versions, main, variables, outputs) |
| 2 | Create static-website fixtures (ACM cert, Route53) |
| 3 | Create shared fixtures (org path, GitHub OIDC) |
| 4 | Add CI IAM role to fixtures |
| 5 | Create artifact-bucket test |
| 6 | Create ecr-repository test |
| 7 | Create static-website test |
| 8 | Create lza-foundation test (validation only) |
| 9 | Create change detection script |
| 10 | Create CI workflow |
| 11 | Deploy test fixtures to platform-dev |
| 12 | Add repository secret and verify tests |
| 13 | Update CLAUDE.md with testing instructions |
