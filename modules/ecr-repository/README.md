# ECR Repository Module

Creates an ECR repository in SharedServices with cross-account pull policy. Designed for use with OE Platform's container deployment workflow.

## Features

- ECR repository with encryption and vulnerability scanning
- Cross-account pull policy using AWS Organizations paths
- Lifecycle policy for automatic image cleanup
- Support for both mutable and immutable tags

## Usage

```hcl
module "ecr" {
  source = "github.com/org/platform-modules//modules/ecr-repository?ref=ecr-repository-v1.0.0"

  name              = "client-slug/web-app"
  organization_path = "o-abc123/r-root/ou-workloads"

  tags = {
    Application = "web-app"
    Client      = "client-slug"
  }
}

# Output the repository URI for use in CI/CD
output "ecr_repository_uri" {
  value = module.ecr.repository_uri
}
```

## Platform Integration

After the ECR repository is created:

1. Update the application repository's `ecr_repository_uri` field in Platform
2. Re-scaffold the application repository to update GitHub Actions variables
3. The build workflow will push images to this repository

The repository URL follows the pattern:
```
{account-id}.dkr.ecr.{region}.amazonaws.com/{repository-name}
```

## Cross-Account Access

The module creates a repository policy that allows any account in the specified Organizations path to pull images. This enables:

- SharedServices: Push images during CI/CD
- Workload accounts (dev, staging, prod): Pull images for ECS deployments

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | ECR repository name | `string` | n/a | yes |
| image_tag_mutability | Tag mutability (MUTABLE or IMMUTABLE) | `string` | `"MUTABLE"` | no |
| scan_on_push | Enable vulnerability scanning | `bool` | `true` | no |
| encryption_type | Encryption type (AES256 or KMS) | `string` | `"AES256"` | no |
| kms_key_arn | KMS key ARN (if using KMS encryption) | `string` | `null` | no |
| organization_path | AWS Organizations path for cross-account access | `string` | `null` | no |
| enable_lifecycle_policy | Enable lifecycle policy | `bool` | `true` | no |
| untagged_image_expiry_days | Days before untagged images expire | `number` | `30` | no |
| max_image_count | Max tagged images to keep (0 = unlimited) | `number` | `0` | no |
| tags | Tags to apply | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| repository_name | ECR repository name |
| repository_arn | ECR repository ARN |
| repository_url | ECR repository URL |
| repository_uri | ECR repository URI (alias) |
| registry_id | AWS account ID of the registry |

## Naming Convention

Repository names should follow the pattern `{client-slug}/{app-slug}`:
- `acme-corp/web-app`
- `acme-corp/api-service`
- `acme-corp/worker`

This keeps repositories organized by client and allows easy identification.
