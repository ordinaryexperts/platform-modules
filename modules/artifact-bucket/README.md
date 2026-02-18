# Artifact Bucket Module

Creates an S3 bucket in SharedServices for storing build artifacts. Designed for use with OE Platform's S3 artifact deployment workflow.

## Features

- S3 bucket with versioning and encryption
- Cross-account read policy using AWS Organizations paths
- Lifecycle policy for automatic cleanup of old versions
- All public access blocked

## Usage

```hcl
module "artifacts" {
  source = "github.com/org/platform-modules//modules/artifact-bucket?ref=artifact-bucket-v1.0.0"

  bucket_name       = "client-slug-artifacts"
  organization_path = "o-abc123/r-root/ou-workloads"

  tags = {
    Client = "client-slug"
  }
}

# Output the bucket name for use in CI/CD
output "artifact_bucket_name" {
  value = module.artifacts.bucket_name
}
```

## Platform Integration

After the artifact bucket is created:

1. Update the client's `artifact_bucket_name` field in Platform
2. Re-scaffold application repositories to update GitHub Actions variables
3. The build workflow will upload artifacts to this bucket

## Bucket Structure

```
{bucket-name}/
  builds/
    {app-slug}/
      {git-sha}/
        index.html
        assets/
          main.js
          styles.css
        ...
```

Each build creates a new directory under `builds/{app-slug}/{git-sha}/`. This provides:
- Immutable builds (each SHA has its own directory)
- Easy rollback (just deploy a previous SHA)
- Artifact history (versioned, with lifecycle cleanup)

## Cross-Account Access

The module creates a bucket policy that allows any account in the specified Organizations path to read artifacts. This enables:

- SharedServices: Write artifacts during CI/CD
- Workload accounts: Read artifacts during deployments (sync to website bucket)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| bucket_name | S3 bucket name | `string` | n/a | yes |
| organization_path | AWS Organizations path for cross-account access | `string` | `null` | no |
| enable_versioning | Enable S3 versioning | `bool` | `true` | no |
| enable_lifecycle_policy | Enable lifecycle policy | `bool` | `true` | no |
| noncurrent_version_expiry_days | Days before old versions expire | `number` | `90` | no |
| abort_incomplete_multipart_days | Days before incomplete uploads abort | `number` | `7` | no |
| force_destroy | Allow bucket deletion with contents | `bool` | `false` | no |
| tags | Tags to apply | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket_name | S3 bucket name |
| bucket_arn | S3 bucket ARN |
| bucket_domain_name | S3 bucket domain name |
| bucket_regional_domain_name | S3 bucket regional domain name |
| bucket_region | AWS region of the bucket |

## Naming Convention

Bucket names should follow the pattern `{client-slug}-artifacts`:
- `acme-corp-artifacts`
- `example-inc-artifacts`

One bucket per client, shared across all S3 artifact applications.

## Security

- All public access is blocked
- Server-side encryption (AES256) enabled
- Cross-account access restricted to organization members
- Versioning preserves artifact history
