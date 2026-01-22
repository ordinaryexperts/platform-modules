# Terraform AWS LZA Foundation

Terraform module that wraps the [AWS Landing Zone Accelerator (LZA)](https://aws.amazon.com/solutions/implementations/landing-zone-accelerator-on-aws/) CloudFormation deployment.

## Overview

This module:
- Deploys the LZA installer CloudFormation stack
- Creates IAM roles for Platform integration
- Stores configuration in SSM Parameter Store
- Optionally creates API Gateway for external integration

## Usage

```hcl
module "lza_foundation" {
  source = "github.com/ordinaryexperts/platform-modules//modules/lza-foundation?ref=lza-foundation/v1.0.0"

  management_account_email  = "management@example.com"
  log_archive_account_email = "log-archive@example.com"
  audit_account_email       = "audit@example.com"

  github_oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
  platform_github_org      = "your-org"

  accelerator_prefix    = "lza"
  control_tower_enabled = false
  enable_approval_stage = true

  tags = {
    Environment = "production"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6.0 |
| aws | >= 5.0 |

## Prerequisites

Before using this module:

1. Deploy the bootstrap CloudFormation stack in your management account to create:
   - GitHub OIDC provider
   - Deployment IAM role
   - S3 bucket for Terraform state
   - DynamoDB table for state locking

2. Have the required email addresses ready for:
   - Management account
   - Log archive account
   - Audit/security account

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| management_account_email | Email for management account root user | `string` | n/a | yes |
| log_archive_account_email | Email for log archive account root user | `string` | n/a | yes |
| audit_account_email | Email for audit account root user | `string` | n/a | yes |
| github_oidc_provider_arn | ARN of GitHub OIDC provider | `string` | n/a | yes |
| platform_github_org | GitHub organization for role trust | `string` | `"ordinaryexperts"` | no |
| accelerator_prefix | Prefix for all LZA resources | `string` | `"lza"` | no |
| control_tower_enabled | Whether AWS Control Tower is enabled | `bool` | `false` | no |
| enable_single_account_mode | Single account mode for testing | `bool` | `false` | no |
| repository_name | CodeCommit repository name | `string` | `"lza-config"` | no |
| repository_branch_name | Repository branch name | `string` | `"main"` | no |
| enable_approval_stage | Enable manual approval in pipeline | `bool` | `true` | no |
| approval_stage_notify_email | Email for approval notifications | `string` | `""` | no |
| create_platform_api | Create API Gateway for integration | `bool` | `true` | no |
| tags | Additional tags for resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| stack_id | CloudFormation stack ID |
| stack_outputs | Outputs from LZA CloudFormation stack |
| platform_lza_role_arn | IAM role ARN for Platform access |
| platform_lza_role_name | IAM role name for Platform access |
| config_ssm_parameter | SSM parameter path for LZA config |
| accelerator_prefix | Prefix used for LZA resources |
| management_account_id | AWS management account ID |
| region | AWS region |
| pipeline_name | LZA CodePipeline name |
| config_repository | LZA CodeCommit repository name |
| api_gateway_id | Platform API Gateway ID |
| api_gateway_endpoint | Platform API Gateway endpoint |

## Deployment Time

The LZA CloudFormation stack can take 60-90 minutes to deploy. The module sets appropriate timeouts.

## Module Upgrades and LZA Versions

**Important:** This module pins a specific LZA version internally. When you upgrade to a new version of this module, it may include a newer LZA version, which will trigger a CloudFormation stack update and LZA upgrade process (60-90 minutes).

Before upgrading this module:
1. Review the [LZA release notes](https://github.com/awslabs/landing-zone-accelerator-on-aws/releases) for breaking changes
2. Plan for the upgrade window (60-90 minutes)
3. Ensure the approval stage is enabled if you want manual control over the upgrade

## License

Apache 2.0
