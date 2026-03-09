# CLAUDE.md - Platform Modules Repository

This repository contains vetted OpenTofu/Terraform modules maintained by Ordinary Experts for use by OE Platform clients.

## Repository Structure

```
platform-modules/
├── modules/
│   ├── <module-name>/
│   │   ├── module.json       # Module metadata (synced to Platform)
│   │   ├── README.md         # Usage documentation
│   │   ├── main.tf           # Resource definitions
│   │   ├── variables.tf      # Input variables
│   │   ├── outputs.tf        # Output values
│   │   └── versions.tf       # Provider constraints
│   └── ...
├── test-fixtures/             # Shared test infrastructure (platform-dev)
└── scripts/                   # CI/CD and utility scripts
```

## Module Standards

When creating or modifying modules:

### Required Files

Every module MUST have:
- `main.tf` - Primary resource definitions
- `variables.tf` - All input variables
- `outputs.tf` - All output values
- `versions.tf` - Terraform and provider version constraints
- `README.md` - Documentation with usage example
- `module.json` - Module metadata for Platform catalog

### module.json

Every module MUST have a `module.json` that defines metadata synced to OE Platform:

```json
{
  "display_name": "Module Name",
  "description": "One-line description of what the module does",
  "category": "compute",
  "deployment_type": null,
  "well_architected": ["security", "reliability"],
  "features": ["feature1", "feature2"]
}
```

Fields:
- `display_name` (required) - Human-readable name
- `description` (required) - Concise description
- `category` (required) - One of: `storage`, `networking`, `compute`, `security`, `database`, `observability`, `iam`, `landing_zone`, `application`
- `deployment_type` (optional) - `"container"` or `"s3_artifact"` if the module supports app code deployment, otherwise `null`
- `well_architected` (optional) - AWS Well-Architected pillars: `security`, `reliability`, `performance_efficiency`, `cost_optimization`, `operational_excellence`, `sustainability`
- `features` (optional) - Feature tags for AI agent context

### Variable Requirements

All variables MUST have:
```hcl
variable "example" {
  description = "Clear description of what this variable does"
  type        = string  # Always specify type
  default     = null    # Optional: provide sensible default if applicable
}
```

### Output Requirements

All outputs MUST have:
```hcl
output "example" {
  description = "Clear description of what this output provides"
  value       = aws_resource.example.id
}
```

### versions.tf Template

```hcl
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

## Coding Standards

### DO
- Use descriptive resource names: `aws_s3_bucket.data_store` not `aws_s3_bucket.bucket`
- Group related resources together in main.tf
- Use locals for repeated values or complex expressions
- Include sensible defaults where possible
- Add validation blocks for variables where appropriate
- Use `for_each` over `count` when iterating over maps/sets

### DO NOT
- Hardcode AWS account IDs, regions, or other environment-specific values
- Create resources that require manual intervention to destroy
- Use `depends_on` unless absolutely necessary (prefer implicit dependencies)
- Include provider configuration - modules should inherit from root
- Use external data sources for things that should be variables

## Versioning

Modules use path-based semantic versioning with git tags:

```
<module-name>-v<major>.<minor>.<patch>
```

Examples: `static-website-v1.3.0`, `ecs-webapp-v2.0.0`, `shared-services-v1.1.0`

- **Major**: Breaking changes (removed/renamed variables, changed behavior)
- **Minor**: New features (new variables, resources) - backwards compatible
- **Patch**: Bug fixes only

## Git Workflow (Trunk-Based Development)

This repository uses trunk-based development:

- `main` - The single integration branch; all work merges here
- `feature/<module>-<description>` - Short-lived feature branches
- `fix/<module>-<description>` - Bug fix branches

Feature branches should be small and merge frequently to main.

## Releases

Releases are triggered automatically when a tag is pushed:

```bash
# Tag format: <module-name>-v<major>.<minor>.<patch>
git tag -a "ecs-webapp-v2.1.0" -m "ecs-webapp v2.1.0: Add Redis cluster mode"
git push origin "ecs-webapp-v2.1.0"
```

This triggers two things:
1. A GitHub Release with auto-generated release notes
2. A webhook to OE Platform that updates the module catalog (version, metadata from `module.json`, parsed variables/outputs)

**No CHANGELOG.md file is required.** Release notes are:
1. Auto-generated from commit messages between releases
2. Stored as GitHub Releases (visible in the Releases tab)
3. Organized by conventional commit types (features, fixes, other)

To help with release note generation, use conventional commit messages:
- `feat: Add Redis caching support`
- `fix: Correct NAT gateway routing`
- `docs: Update README examples`

## Validation Commands

Before committing, run:
```bash
tofu fmt -recursive
tofu validate  # In each module directory
```

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

## Reference

Modules are sourced by clients using path-based version tags:
```hcl
module "website" {
  source = "github.com/ordinaryexperts/platform-modules//modules/static-website?ref=static-website-v1.3.0"

  # ... module variables
}
```
