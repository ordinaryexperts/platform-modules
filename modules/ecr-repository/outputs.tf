output "repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.this.name
}

output "repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.this.arn
}

output "repository_url" {
  description = "URL of the ECR repository (for docker push/pull)"
  value       = aws_ecr_repository.this.repository_url
}

output "repository_uri" {
  description = "URI of the ECR repository (alias for repository_url)"
  value       = aws_ecr_repository.this.repository_url
}

output "registry_id" {
  description = "Registry ID (AWS account ID) where repository is created"
  value       = aws_ecr_repository.this.registry_id
}
