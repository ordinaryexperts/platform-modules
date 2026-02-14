# =============================================================================
# ECR Outputs
# =============================================================================

output "ecr_repository_name" {
  description = "Name of the ECR repository"
  value       = var.create_ecr_repository ? aws_ecr_repository.this[0].name : null
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = var.create_ecr_repository ? aws_ecr_repository.this[0].arn : null
}

output "ecr_repository_url" {
  description = "URL of the ECR repository (for docker push/pull)"
  value       = var.create_ecr_repository ? aws_ecr_repository.this[0].repository_url : null
}

output "ecr_registry_id" {
  description = "Registry ID (AWS account ID) where repository is created"
  value       = var.create_ecr_repository ? aws_ecr_repository.this[0].registry_id : null
}

# =============================================================================
# Artifact Bucket Outputs
# =============================================================================

output "artifact_bucket_name" {
  description = "Name of the S3 artifact bucket"
  value       = var.create_artifact_bucket ? aws_s3_bucket.artifacts[0].id : null
}

output "artifact_bucket_arn" {
  description = "ARN of the S3 artifact bucket"
  value       = var.create_artifact_bucket ? aws_s3_bucket.artifacts[0].arn : null
}

output "artifact_bucket_domain_name" {
  description = "Domain name of the S3 artifact bucket"
  value       = var.create_artifact_bucket ? aws_s3_bucket.artifacts[0].bucket_domain_name : null
}

output "artifact_bucket_regional_domain_name" {
  description = "Regional domain name of the S3 artifact bucket"
  value       = var.create_artifact_bucket ? aws_s3_bucket.artifacts[0].bucket_regional_domain_name : null
}

output "artifact_bucket_region" {
  description = "AWS region where the artifact bucket is located"
  value       = var.create_artifact_bucket ? aws_s3_bucket.artifacts[0].region : null
}
