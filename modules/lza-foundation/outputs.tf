# LZA Foundation Module - Outputs

output "stack_id" {
  description = "CloudFormation stack ID of the LZA installer"
  value       = aws_cloudformation_stack.lza_installer.id
}

output "stack_outputs" {
  description = "Outputs from the LZA CloudFormation stack"
  value       = aws_cloudformation_stack.lza_installer.outputs
}

output "config_ssm_parameter" {
  description = "SSM parameter path containing LZA configuration"
  value       = aws_ssm_parameter.lza_config.name
}

output "accelerator_prefix" {
  description = "Prefix used for all LZA resources"
  value       = var.accelerator_prefix
}

output "management_account_id" {
  description = "AWS account ID of the management account"
  value       = data.aws_caller_identity.current.account_id
}

output "region" {
  description = "AWS region where LZA is deployed"
  value       = data.aws_region.current.id
}

output "pipeline_name" {
  description = "Name of the LZA CodePipeline"
  value       = "${var.accelerator_prefix}-Pipeline"
}

output "config_bucket_name" {
  description = "S3 bucket name for LZA configuration files"
  value       = local.config_bucket_name
}

output "config_bucket_key" {
  description = "S3 object key for the zipped LZA configuration"
  value       = "zipped/aws-accelerator-config.zip"
}

output "pipeline_poller_user_arn" {
  description = "ARN of the IAM user for GitHub Actions pipeline polling"
  value       = aws_iam_user.pipeline_poller.arn
}

output "pipeline_poller_user_name" {
  description = "Name of the IAM user for GitHub Actions pipeline polling (for creating access keys)"
  value       = aws_iam_user.pipeline_poller.name
}

