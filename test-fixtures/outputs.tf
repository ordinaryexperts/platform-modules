# test-fixtures/outputs.tf
# Outputs are also stored in SSM for test consumption

output "certificate_arn" {
  description = "ACM certificate ARN for static-website tests"
  value       = aws_acm_certificate.test.arn
}

output "organization_path" {
  description = "Organization path for cross-account tests"
  value       = var.organization_path
}

output "github_oidc_provider_arn" {
  description = "GitHub OIDC provider ARN for lza-foundation tests"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "test_role_arn" {
  description = "IAM role ARN for CI test runs"
  value       = aws_iam_role.ci_test.arn
}
