# test-fixtures/main.tf
#
# Shared test fixtures for platform-modules integration tests.
# Deploy once to platform-dev, outputs stored in SSM for test consumption.

provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
