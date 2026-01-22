# LZA Foundation Module
#
# This module wraps the AWS Landing Zone Accelerator (LZA) CloudFormation
# deployment, providing a standardized way to deploy LZA for Platform clients.
#
# The module:
# - Deploys the LZA installer CloudFormation stack
# - Configures standard organizational units and SCPs
# - Sets up the API Gateway for Platform integration
# - Creates necessary IAM roles for cross-account access

locals {
  stack_name = "AWSAccelerator-Installer"

  # LZA CloudFormation template URL - pinned to specific version for predictable deployments.
  # Updating this module version may trigger an LZA upgrade (60-90 minute process).
  # See: https://github.com/awslabs/landing-zone-accelerator-on-aws/releases
  lza_template_url = "https://s3.amazonaws.com/solutions-reference/landing-zone-accelerator-on-aws/v1.14.2/AWSAccelerator-InstallerStack.template"

  # LZA configuration defaults
  lza_config = {
    accelerator_prefix             = var.accelerator_prefix
    management_account_email       = var.management_account_email
    log_archive_account_email      = var.log_archive_account_email
    audit_account_email            = var.audit_account_email
    control_tower_enabled          = var.control_tower_enabled
    repository_name                = var.repository_name
    repository_branch_name         = var.repository_branch_name
    enable_approval_stage          = var.enable_approval_stage
    approval_stage_notify_email    = var.approval_stage_notify_email
  }

  tags = merge(var.tags, {
    ManagedBy    = "OE-Platform"
    Module       = "lza-foundation"
    ModuleSource = "github.com/ordinaryexperts/platform-modules//modules/lza-foundation"
  })
}

# Data source to get current AWS account and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Deploy the LZA Installer CloudFormation stack
resource "aws_cloudformation_stack" "lza_installer" {
  name         = local.stack_name
  capabilities = ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM", "CAPABILITY_AUTO_EXPAND"]

  # LZA CloudFormation template URL - pinned in locals
  template_url = local.lza_template_url

  parameters = {
    ConfigurationRepositoryLocation = var.configuration_repository_location
    AcceleratorPrefix            = local.lza_config.accelerator_prefix
    ManagementAccountEmail       = local.lza_config.management_account_email
    LogArchiveAccountEmail       = local.lza_config.log_archive_account_email
    AuditAccountEmail            = local.lza_config.audit_account_email
    ControlTowerEnabled          = local.lza_config.control_tower_enabled ? "Yes" : "No"
    # RepositoryName defaults to "landing-zone-accelerator-on-aws" (the LZA source code repo)
    # RepositoryBranchName defaults to "main"
    EnableApprovalStage          = local.lza_config.enable_approval_stage ? "Yes" : "No"
    ApprovalStageNotifyEmailList = local.lza_config.approval_stage_notify_email
  }

  tags = local.tags

  # LZA deployment can take a while
  timeouts {
    create = "90m"
    update = "90m"
    delete = "60m"
  }
}

# Create the Platform access role in management account
# This role is used by the Platform to interact with LZA APIs
resource "aws_iam_role" "platform_lza_access" {
  name        = "${var.accelerator_prefix}-PlatformLzaAccess"
  description = "Role for OE Platform to access LZA APIs and Step Functions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.github_oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.platform_github_org}/*"
          }
        }
      }
    ]
  })

  tags = local.tags
}

# Policy for Platform to invoke LZA Step Functions and APIs
resource "aws_iam_role_policy" "platform_lza_access" {
  name = "LzaAccessPolicy"
  role = aws_iam_role.platform_lza_access.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "InvokeAccountVendingStepFunction"
        Effect = "Allow"
        Action = [
          "states:StartExecution",
          "states:DescribeExecution",
          "states:GetExecutionHistory"
        ]
        Resource = [
          "arn:aws:states:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:stateMachine:${var.accelerator_prefix}-*"
        ]
      },
      {
        Sid    = "InvokeLzaApiGateway"
        Effect = "Allow"
        Action = [
          "execute-api:Invoke"
        ]
        Resource = [
          "arn:aws:execute-api:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:*"
        ]
      },
      {
        Sid    = "ReadOrganizations"
        Effect = "Allow"
        Action = [
          "organizations:ListAccounts",
          "organizations:ListOrganizationalUnitsForParent",
          "organizations:ListRoots",
          "organizations:DescribeAccount",
          "organizations:DescribeOrganization",
          "organizations:DescribeOrganizationalUnit"
        ]
        Resource = "*"
      },
      {
        Sid    = "ReadCodeCommit"
        Effect = "Allow"
        Action = [
          "codecommit:GetRepository",
          "codecommit:GetBranch",
          "codecommit:GetFile",
          "codecommit:GetFolder"
        ]
        Resource = [
          "arn:aws:codecommit:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:${var.accelerator_prefix}-config"
        ]
      }
    ]
  })
}

# Create API Gateway for Platform integration
# This provides a REST API for account provisioning
resource "aws_api_gateway_rest_api" "platform_integration" {
  count = var.create_platform_api ? 1 : 0

  name        = "${var.accelerator_prefix}-platform-integration"
  description = "API Gateway for OE Platform to interact with LZA"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = local.tags
}

# Store LZA configuration in SSM for Platform to retrieve
resource "aws_ssm_parameter" "lza_config" {
  name        = "/${var.accelerator_prefix}/platform/config"
  description = "LZA configuration for OE Platform integration"
  type        = "String"
  value = jsonencode({
    accelerator_prefix    = var.accelerator_prefix
    repository_name       = var.repository_name
    management_account_id = data.aws_caller_identity.current.account_id
    region                = data.aws_region.current.id
    pipeline_name         = "${var.accelerator_prefix}-Pipeline"
    config_repo           = "${var.accelerator_prefix}-config"
    platform_role_arn     = aws_iam_role.platform_lza_access.arn
  })

  tags = local.tags
}
