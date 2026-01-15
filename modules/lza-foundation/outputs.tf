# LZA Foundation Module - Outputs

output "stack_id" {
  description = "CloudFormation stack ID of the LZA installer"
  value       = aws_cloudformation_stack.lza_installer.id
}

output "stack_outputs" {
  description = "Outputs from the LZA CloudFormation stack"
  value       = aws_cloudformation_stack.lza_installer.outputs
}

output "platform_lza_role_arn" {
  description = "ARN of the IAM role for Platform to access LZA"
  value       = aws_iam_role.platform_lza_access.arn
}

output "platform_lza_role_name" {
  description = "Name of the IAM role for Platform to access LZA"
  value       = aws_iam_role.platform_lza_access.name
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
  value       = data.aws_region.current.name
}

output "pipeline_name" {
  description = "Name of the LZA CodePipeline"
  value       = "${var.accelerator_prefix}-Pipeline"
}

output "config_repository" {
  description = "Name of the LZA configuration CodeCommit repository"
  value       = "${var.accelerator_prefix}-config"
}

output "api_gateway_id" {
  description = "ID of the Platform integration API Gateway"
  value       = var.create_platform_api ? aws_api_gateway_rest_api.platform_integration[0].id : null
}

output "api_gateway_endpoint" {
  description = "Endpoint URL for the Platform integration API Gateway"
  value       = var.create_platform_api ? aws_api_gateway_rest_api.platform_integration[0].execution_arn : null
}
