# test-fixtures/artifact-bucket.tf
#
# Test fixtures for the artifact-bucket module:
# - Organization path stored in SSM

resource "aws_ssm_parameter" "organization_path" {
  name        = "/platform-test/organization-path"
  description = "AWS Organizations path for cross-account policy tests"
  type        = "String"
  value       = var.organization_path

  tags = var.tags
}
