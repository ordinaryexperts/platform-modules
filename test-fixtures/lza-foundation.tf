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
