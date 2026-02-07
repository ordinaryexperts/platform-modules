# LZA Foundation Module
#
# This module wraps the AWS Landing Zone Accelerator (LZA) CloudFormation
# deployment, providing a standardized way to deploy LZA for Platform clients.
#
# The module:
# - Deploys the LZA installer CloudFormation stack
# - Stores LZA configuration in SSM for Platform integration
# - Configures Lambda concurrency limits for new account compatibility

locals {
  stack_name = "AWSAccelerator-Installer"

  # LZA CloudFormation template URL - pinned to specific version for predictable deployments.
  # Updating this module version may trigger an LZA upgrade (60-90 minute process).
  # See: https://github.com/awslabs/landing-zone-accelerator-on-aws/releases
  lza_template_url = "https://s3.amazonaws.com/solutions-reference/landing-zone-accelerator-on-aws/v1.14.2/AWSAccelerator-InstallerStack.template"

  # LZA configuration defaults
  lza_config = {
    accelerator_prefix          = var.accelerator_prefix
    management_account_email    = var.management_account_email
    log_archive_account_email   = var.log_archive_account_email
    audit_account_email         = var.audit_account_email
    control_tower_enabled       = var.control_tower_enabled
    enable_approval_stage       = var.enable_approval_stage
    approval_stage_notify_email = var.approval_stage_notify_email
  }

  # S3 bucket name for LZA configuration (created automatically by LZA when using S3 source)
  config_bucket_name = "aws-accelerator-config-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.id}"

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
    # LZA source code repository settings
    RepositorySource     = var.lza_source_location
    RepositoryOwner      = var.lza_source_owner
    RepositoryName       = var.lza_source_repo_name
    RepositoryBranchName = var.lza_source_branch

    # LZA configuration repository location - always S3
    # The GitHub workflow uploads config files to S3, enabling deploy-before-merge
    ConfigurationRepositoryLocation = "s3"

    # Core LZA settings
    AcceleratorPrefix      = local.lza_config.accelerator_prefix
    ManagementAccountEmail = local.lza_config.management_account_email
    LogArchiveAccountEmail = local.lza_config.log_archive_account_email
    AuditAccountEmail      = local.lza_config.audit_account_email
    ControlTowerEnabled    = local.lza_config.control_tower_enabled ? "Yes" : "No"

    # Pipeline settings
    EnableApprovalStage          = local.lza_config.enable_approval_stage ? "Yes" : "No"
    ApprovalStageNotifyEmailList = local.lza_config.approval_stage_notify_email

    # Diagnostics
    EnableDiagnosticsPack = var.enable_diagnostics_pack ? "Yes" : "No"
  }

  tags = local.tags

  # LZA deployment can take a while
  timeouts {
    create = "90m"
    update = "90m"
    delete = "60m"
  }
}

# Update the Toolkit CodeBuild project with Lambda concurrency limit
# This bypasses the Lambda concurrent execution validation that fails on new accounts
# See: https://github.com/awslabs/landing-zone-accelerator-on-aws/issues/984
resource "null_resource" "toolkit_lambda_concurrency" {
  count = var.lambda_concurrency_limit > 0 ? 1 : 0

  triggers = {
    stack_id          = aws_cloudformation_stack.lza_installer.id
    concurrency_limit = var.lambda_concurrency_limit
  }

  provisioner "local-exec" {
    environment = {
      AWS_REGION     = data.aws_region.current.name
      PROJECT_NAME   = "${var.accelerator_prefix}-ToolkitProject"
      CONCURRENCY    = var.lambda_concurrency_limit
    }

    command = <<-EOT
      set -e

      # Get current environment variables from the Toolkit project
      CURRENT_ENV=$(aws codebuild batch-get-projects \
        --names "$PROJECT_NAME" \
        --query 'projects[0].environment.environmentVariables' \
        --output json)

      # Add the concurrency limit variable (unique_by prevents duplicates)
      NEW_ENV=$(echo "$CURRENT_ENV" | jq --arg limit "$CONCURRENCY" \
        '. + [{"name": "ACCELERATOR_LAMBDA_CONCURRENCY_LIMIT", "value": $limit, "type": "PLAINTEXT"}] | unique_by(.name)')

      # Get full environment config and update variables, writing to temp file
      # to avoid shell escaping issues with complex JSON
      TEMP_FILE=$(mktemp)
      aws codebuild batch-get-projects \
        --names "$PROJECT_NAME" \
        --query 'projects[0].environment' \
        --output json | jq --argjson envVars "$NEW_ENV" '.environmentVariables = $envVars' > "$TEMP_FILE"

      # Update the CodeBuild project using file input
      aws codebuild update-project \
        --name "$PROJECT_NAME" \
        --environment "file://$TEMP_FILE"

      rm -f "$TEMP_FILE"
      echo "Successfully added ACCELERATOR_LAMBDA_CONCURRENCY_LIMIT=$CONCURRENCY to $PROJECT_NAME"
    EOT
  }

  depends_on = [aws_cloudformation_stack.lza_installer]
}

# Store LZA configuration in SSM for Platform to retrieve
resource "aws_ssm_parameter" "lza_config" {
  name        = "/${var.accelerator_prefix}/platform/config"
  description = "LZA configuration for OE Platform integration"
  type        = "String"
  value = jsonencode({
    accelerator_prefix    = var.accelerator_prefix
    lza_source_repo       = var.lza_source_repo_name
    management_account_id = data.aws_caller_identity.current.account_id
    region                = data.aws_region.current.id
    pipeline_name         = "${var.accelerator_prefix}-Pipeline"
    config_bucket         = local.config_bucket_name
  })

  tags = local.tags
}
