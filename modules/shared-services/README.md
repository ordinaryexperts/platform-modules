# Shared Services Module

Creates shared infrastructure resources in a SharedServices AWS account. Supports ECR repositories for container image storage and S3 artifact buckets for build artifacts, each independently togglable.

## Usage

```hcl
module "shared_services" {
  source = "github.com/ordinaryexperts/platform-modules//modules/shared-services?ref=shared-services-v1.0.0"

  # Both resources enabled by default
  ecr_repository_name  = "123456789012-client-slug/web-app"
  artifact_bucket_name = "123456789012-client-slug-artifacts"
  organization_path    = "o-abc123/r-root/ou-workloads"
}
```

### ECR Only

```hcl
module "shared_services" {
  source = "github.com/ordinaryexperts/platform-modules//modules/shared-services?ref=shared-services-v1.0.0"

  create_artifact_bucket = false
  ecr_repository_name    = "123456789012-client-slug/web-app"
  organization_path      = "o-abc123/r-root/ou-workloads"
}
```

### Artifact Bucket Only

```hcl
module "shared_services" {
  source = "github.com/ordinaryexperts/platform-modules//modules/shared-services?ref=shared-services-v1.0.0"

  create_ecr_repository = false
  artifact_bucket_name  = "123456789012-client-slug-artifacts"
  organization_path     = "o-abc123/r-root/ou-workloads"
}
```

## Resources Created

### ECR Repository (when `create_ecr_repository = true`)

| Resource | Description |
|----------|-------------|
| `aws_ecr_repository` | Container image repository with encryption and scanning |
| `aws_ecr_repository_policy` | Cross-account pull policy via organization path |
| `aws_ecr_lifecycle_policy` | Cleanup of untagged images (optional) |

### Artifact Bucket (when `create_artifact_bucket = true`)

| Resource | Description |
|----------|-------------|
| `aws_s3_bucket` | Build artifact storage |
| `aws_s3_bucket_versioning` | Version history for artifacts |
| `aws_s3_bucket_server_side_encryption_configuration` | AES256 encryption |
| `aws_s3_bucket_public_access_block` | All public access blocked |
| `aws_s3_bucket_policy` | Cross-account read policy via organization path |
| `aws_s3_bucket_lifecycle_configuration` | Cleanup of old versions (optional) |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `create_ecr_repository` | Whether to create an ECR repository | `bool` | `true` | no |
| `create_artifact_bucket` | Whether to create an S3 artifact bucket | `bool` | `true` | no |
| `organization_path` | AWS Organizations path for cross-account policies | `string` | `null` | no |
| `tags` | Tags to apply to all resources | `map(string)` | `{}` | no |
| `ecr_repository_name` | ECR repository name | `string` | `null` | when ECR enabled |
| `ecr_image_tag_mutability` | Tag mutability (MUTABLE/IMMUTABLE) | `string` | `"IMMUTABLE"` | no |
| `ecr_scan_on_push` | Enable vulnerability scanning | `bool` | `true` | no |
| `ecr_encryption_type` | Encryption type (AES256/KMS) | `string` | `"AES256"` | no |
| `ecr_kms_key_arn` | KMS key ARN (when encryption_type is KMS) | `string` | `null` | no |
| `ecr_enable_lifecycle_policy` | Enable image cleanup policy | `bool` | `true` | no |
| `ecr_untagged_image_expiry_days` | Days to keep untagged images | `number` | `30` | no |
| `ecr_max_image_count` | Max tagged images to keep (0 = unlimited) | `number` | `0` | no |
| `artifact_bucket_name` | S3 bucket name | `string` | `null` | when bucket enabled |
| `artifact_enable_versioning` | Enable S3 versioning | `bool` | `true` | no |
| `artifact_enable_lifecycle_policy` | Enable artifact cleanup policy | `bool` | `true` | no |
| `artifact_noncurrent_version_expiry_days` | Days before old versions deleted | `number` | `90` | no |
| `artifact_abort_incomplete_multipart_days` | Days before incomplete uploads aborted | `number` | `7` | no |
| `artifact_force_destroy` | Allow bucket destruction with objects | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| `ecr_repository_name` | Name of the ECR repository |
| `ecr_repository_arn` | ARN of the ECR repository |
| `ecr_repository_url` | URL for docker push/pull |
| `ecr_registry_id` | Registry ID (AWS account ID) |
| `artifact_bucket_name` | Name of the S3 bucket |
| `artifact_bucket_arn` | ARN of the S3 bucket |
| `artifact_bucket_domain_name` | Domain name of the bucket |
| `artifact_bucket_regional_domain_name` | Regional domain name |
| `artifact_bucket_region` | AWS region of the bucket |
