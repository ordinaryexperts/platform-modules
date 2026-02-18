# Artifact Bucket Module
#
# Creates an S3 bucket in SharedServices for storing build artifacts.
# Designed for use with OE Platform's S3 artifact deployment workflow.
#
# Resources created:
# - S3 bucket with versioning and encryption
# - Bucket policy for cross-account read access
# - Lifecycle policy for cleanup (optional)
# - Public access block (all public access blocked)
#
# Bucket structure:
#   {bucket-name}/
#     builds/
#       {app-slug}/
#         {git-sha}/
#           index.html
#           assets/
#           ...
#
# Usage:
#   module "artifacts" {
#     source = "github.com/org/platform-modules//modules/artifact-bucket?ref=artifact-bucket-v1.0.0"
#
#     bucket_name       = "client-slug-artifacts"
#     organization_path = "o-abc123/r-root/ou-workloads"
#   }

# =============================================================================
# S3 Bucket
# =============================================================================

resource "aws_s3_bucket" "artifacts" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = merge(var.tags, {
    Name      = var.bucket_name
    Purpose   = "build-artifacts"
    ManagedBy = "platform"
  })
}

# =============================================================================
# Bucket Configuration
# =============================================================================

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# =============================================================================
# Cross-Account Read Policy
# =============================================================================

resource "aws_s3_bucket_policy" "cross_account" {
  count  = var.organization_path != null ? 1 : 0
  bucket = aws_s3_bucket.artifacts.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCrossAccountRead"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.artifacts.arn,
          "${aws_s3_bucket.artifacts.arn}/*"
        ]
        Condition = {
          "ForAnyValue:StringLike" = {
            "aws:PrincipalOrgPaths" = ["${var.organization_path}/*"]
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.artifacts]
}

# =============================================================================
# Lifecycle Policy
# =============================================================================

resource "aws_s3_bucket_lifecycle_configuration" "artifacts" {
  count  = var.enable_lifecycle_policy ? 1 : 0
  bucket = aws_s3_bucket.artifacts.id

  rule {
    id     = "cleanup-old-versions"
    status = "Enabled"

    filter {
      prefix = "builds/"
    }

    # Delete noncurrent versions after N days
    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiry_days
    }

    # Clean up incomplete multipart uploads
    abort_incomplete_multipart_upload {
      days_after_initiation = var.abort_incomplete_multipart_days
    }
  }
}
