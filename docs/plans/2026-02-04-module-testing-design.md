# Module Testing Design

## Overview

This design establishes a testing framework for platform-modules using OpenTofu's native `tofu test` command. Testing happens at two levels:

1. **Validation** - Format and syntax checks on every PR (fast, no AWS)
2. **Integration** - Deploy and verify modules in platform-dev account (on changed modules only)

## Directory Structure

```
platform-modules/
├── modules/
│   ├── artifact-bucket/
│   │   ├── main.tf, variables.tf, etc.
│   │   └── tests/
│   │       └── basic.tftest.hcl
│   ├── ecr-repository/
│   │   └── tests/
│   │       └── basic.tftest.hcl
│   ├── static-website/
│   │   └── tests/
│   │       └── basic.tftest.hcl
│   └── lza-foundation/
│       └── tests/
│           └── basic.tftest.hcl      # Validation-only (90min deploy)
├── test-fixtures/
│   ├── main.tf                        # Provider config, data sources
│   ├── variables.tf
│   ├── outputs.tf
│   ├── versions.tf
│   ├── static-website.tf              # ACM certificate
│   ├── lza-foundation.tf              # GitHub OIDC provider
│   ├── artifact-bucket.tf             # Organization path lookup
│   └── ecr-repository.tf              # Organization path (shared)
├── .github/
│   └── workflows/
│       └── test.yml
└── scripts/
    └── detect-changed-modules.sh
```

## Test Fixtures

Shared AWS resources deployed once to platform-dev and persisted. Tests consume fixture values via SSM parameters, decoupling test runs from fixture state.

### Fixture Files (named by module)

- `static-website.tf` - ACM certificate for CloudFront tests
- `lza-foundation.tf` - GitHub OIDC provider ARN
- `artifact-bucket.tf` - Organization path data lookup
- `ecr-repository.tf` - Organization path (may share with artifact-bucket)

### SSM Parameter Convention

Fixtures write outputs to SSM under `/platform-test/`:

```hcl
resource "aws_ssm_parameter" "certificate_arn" {
  name  = "/platform-test/static-website/certificate-arn"
  type  = "String"
  value = aws_acm_certificate.test.arn
}

resource "aws_ssm_parameter" "organization_path" {
  name  = "/platform-test/organization-path"
  type  = "String"
  value = "o-xxx/r-xxx/ou-xxx"
}
```

## Test File Structure

Each module's test follows this pattern:

```hcl
# modules/artifact-bucket/tests/basic.tftest.hcl

provider "aws" {
  region = "us-east-1"
}

variables {
  bucket_name       = "platform-test-artifacts-${run.id}"
  organization_path = provider::aws::ssm_parameter_value("/platform-test/organization-path")
}

run "creates_bucket_with_versioning" {
  command = apply

  assert {
    condition     = aws_s3_bucket_versioning.artifacts.versioning_configuration[0].status == "Enabled"
    error_message = "Bucket versioning should be enabled by default"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.artifacts.block_public_acls == true
    error_message = "Public access should be blocked"
  }
}
```

### Test Naming Convention

- `basic.tftest.hcl` - Core functionality, always runs
- `cross-account.tftest.hcl` - Tests requiring org path (optional)

### lza-foundation Exception

The lza-foundation module takes 60-90 minutes to deploy. Its tests will be validation-only (no `apply`), checking variable validation and plan output.

## CI Workflow

```yaml
# .github/workflows/test.yml

name: Test Modules

on:
  pull_request:
    branches: [main]

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
      - id: changes
        run: ./scripts/detect-changed-modules.sh

  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: opentofu/setup-opentofu@v1
      - name: Format check
        run: tofu fmt -check -recursive
      - name: Validate all modules
        run: |
          for dir in modules/*/; do
            echo "Validating $dir"
            tofu -chdir="$dir" init -backend=false
            tofu -chdir="$dir" validate
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
      - uses: opentofu/setup-opentofu@v1
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_TEST_ROLE_ARN }}
          aws-region: us-east-1
      - name: Run tests
        run: tofu -chdir="modules/${{ matrix.module }}" test
```

### CI Behavior

- **Validation**: Runs on all modules (fast, no AWS cost)
- **Integration**: Runs only on changed modules via matrix strategy
- **AWS Auth**: OIDC-based (no long-lived credentials)
- **Failure handling**: `fail-fast: false` ensures all modules get tested

## Change Detection Script

```bash
#!/usr/bin/env bash
# scripts/detect-changed-modules.sh
set -euo pipefail

BASE_REF="${GITHUB_BASE_REF:-main}"

# Get list of changed files compared to base branch
changed_files=$(git diff --name-only "origin/$BASE_REF"...HEAD)

# Extract unique module names from changed paths
modules=()
while IFS= read -r file; do
  if [[ "$file" =~ ^modules/([^/]+)/ ]]; then
    module="${BASH_REMATCH[1]}"
    # Skip lza-foundation (validation-only)
    if [[ "$module" != "lza-foundation" ]]; then
      modules+=("$module")
    fi
  fi
done <<< "$changed_files"

# Deduplicate
unique_modules=($(printf '%s\n' "${modules[@]}" | sort -u))

# Output for GitHub Actions
if [[ ${#unique_modules[@]} -eq 0 ]]; then
  echo "modules=[]" >> "$GITHUB_OUTPUT"
  echo "has_changes=false" >> "$GITHUB_OUTPUT"
else
  json=$(printf '%s\n' "${unique_modules[@]}" | jq -R . | jq -s -c .)
  echo "modules=$json" >> "$GITHUB_OUTPUT"
  echo "has_changes=true" >> "$GITHUB_OUTPUT"
fi
```

## AI Worker Workflow

Before committing module changes, AI workers should:

```bash
cd modules/<module-name>
tofu test
```

This validates changes locally before creating commits.

## Implementation Tasks

1. Create `test-fixtures/` with shared AWS resources
2. Deploy test-fixtures to platform-dev (one-time setup)
3. Add `tests/basic.tftest.hcl` to each module
4. Create `.github/workflows/test.yml`
5. Create `scripts/detect-changed-modules.sh`
6. Create AWS IAM role for CI (OIDC-based)
7. Add `AWS_TEST_ROLE_ARN` secret to repository
