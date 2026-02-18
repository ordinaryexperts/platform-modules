# test-fixtures/versions.tf
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  backend "s3" {
    bucket = "oe-platform-dev-terraform-state"
    key    = "platform-modules/test-fixtures/terraform.tfstate"
    region = "us-east-1"
  }
}
