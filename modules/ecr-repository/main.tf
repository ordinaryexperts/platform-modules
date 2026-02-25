# ECR Repository Module
#
# Creates an ECR repository in SharedServices with cross-account pull policy.
# Designed for use with OE Platform's container deployment workflow.
#
# Resources created:
# - ECR repository with encryption and scanning
# - Repository policy for cross-account pull access
# - Lifecycle policy for image cleanup (optional)
#
# Usage:
#   module "ecr" {
#     source = "github.com/org/platform-modules//modules/ecr-repository?ref=ecr-repository-v1.0.0"
#
#     name              = "client-slug/web-app"
#     organization_path = "o-abc123/r-root/ou-workloads"
#   }

# =============================================================================
# ECR Repository
# =============================================================================

resource "aws_ecr_repository" "this" {
  name                 = var.name
  image_tag_mutability = var.image_tag_mutability

  dynamic "image_tag_mutability_exclusion_filter" {
    for_each = var.image_tag_mutability == "IMMUTABLE_WITH_EXCLUSION" ? var.mutable_tag_patterns : []
    content {
      filter      = image_tag_mutability_exclusion_filter.value
      filter_type = "WILDCARD"
    }
  }

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = var.encryption_type
    kms_key         = var.encryption_type == "KMS" ? var.kms_key_arn : null
  }

  tags = merge(var.tags, {
    Name      = var.name
    ManagedBy = "platform"
  })
}

# =============================================================================
# Cross-Account Pull Policy
# =============================================================================

resource "aws_ecr_repository_policy" "cross_account" {
  count      = var.organization_path != null ? 1 : 0
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCrossAccountPull"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
        Condition = {
          "ForAnyValue:StringLike" = {
            "aws:PrincipalOrgPaths" = ["${var.organization_path}/*"]
          }
        }
      }
    ]
  })
}

# =============================================================================
# Cross-Account Pull Policy (explicit account IDs)
# =============================================================================

resource "aws_ecr_repository_policy" "allowed_accounts" {
  count      = length(var.allowed_account_ids) > 0 && var.organization_path == null ? 1 : 0
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCrossAccountPull"
        Effect = "Allow"
        Principal = {
          AWS = [for id in var.allowed_account_ids : "arn:aws:iam::${id}:root"]
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      }
    ]
  })
}

# =============================================================================
# Lifecycle Policy
# =============================================================================

resource "aws_ecr_lifecycle_policy" "this" {
  count      = var.enable_lifecycle_policy ? 1 : 0
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = concat(
      # Rule 1: Remove untagged images after N days
      [
        {
          rulePriority = 1
          description  = "Remove untagged images after ${var.untagged_image_expiry_days} days"
          selection = {
            tagStatus   = "untagged"
            countType   = "sinceImagePushed"
            countUnit   = "days"
            countNumber = var.untagged_image_expiry_days
          }
          action = {
            type = "expire"
          }
        }
      ],
      # Rule 2: Keep only N most recent tagged images (if max_image_count > 0)
      var.max_image_count > 0 ? [
        {
          rulePriority = 2
          description  = "Keep only ${var.max_image_count} most recent tagged images"
          selection = {
            tagStatus     = "tagged"
            tagPrefixList = ["v", "sha-", "latest"]
            countType     = "imageCountMoreThan"
            countNumber   = var.max_image_count
          }
          action = {
            type = "expire"
          }
        }
      ] : []
    )
  })
}
