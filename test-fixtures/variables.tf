# test-fixtures/variables.tf

variable "test_domain" {
  description = "Domain name for test resources (must have Route53 hosted zone)"
  type        = string
}

variable "organization_path" {
  description = "AWS Organizations path for cross-account tests"
  type        = string
}

variable "tags" {
  description = "Tags for all test fixture resources"
  type        = map(string)
  default = {
    Purpose   = "platform-modules-testing"
    ManagedBy = "tofu"
  }
}
