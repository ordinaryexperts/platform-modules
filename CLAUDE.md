# CLAUDE.md - Platform Modules Repository

This repository contains vetted OpenTofu/Terraform modules maintained by Ordinary Experts for use by OE Platform clients.

## Repository Structure

```
platform-modules/
├── modules/
│   ├── <module-name>/
│   │   ├── README.md        # Usage documentation
│   │   ├── main.tf          # Resource definitions
│   │   ├── variables.tf     # Input variables
│   │   ├── outputs.tf       # Output values
│   │   └── versions.tf      # Provider constraints
│   └── ...
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
<module-name>/v<major>.<minor>.<patch>
```

Examples: `s3-bucket/v1.0.0`, `vpc/v2.1.0`, `web-app/v1.3.0`

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

Releases are triggered automatically when a path-based tag is pushed:

```bash
# Tag format: <module-name>/v<major>.<minor>.<patch>
git tag lza-foundation/v1.0.0
git push origin lza-foundation/v1.0.0
```

This creates a GitHub Release with auto-generated release notes.

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

## Reference

Modules are sourced by clients using path-based version tags:
```hcl
# Example: Using the s3-bucket module at version 1.2.0
module "bucket" {
  source = "github.com/ordinaryexperts/platform-modules//modules/s3-bucket?ref=s3-bucket/v1.2.0"

  # ... module variables
}
```
