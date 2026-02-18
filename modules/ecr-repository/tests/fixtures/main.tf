# modules/ecr-repository/tests/fixtures/main.tf

data "aws_ssm_parameter" "organization_path" {
  name = "/platform-test/organization-path"
}

resource "random_id" "test" {
  byte_length = 4
}

output "organization_path" {
  value = data.aws_ssm_parameter.organization_path.value
}

output "test_id" {
  value = random_id.test.hex
}
