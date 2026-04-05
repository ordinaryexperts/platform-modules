# Changelog

All notable changes to this module are documented in this file.

## [2.0.0] - 2026-03-30

### Changed
- **Breaking**: Replaced single shared ECR with per-app ECR repositories via `ecr_repositories` map variable
- Per-app lifecycle policies with configurable image retention

### Added
- `ecr_repositories` variable for declaring per-application ECR repositories

### Removed
- Single `ecr_repository_name` variable (replaced by `ecr_repositories` map)

## [1.1.0] - 2026-03-08

### Added
- `artifact_bucket_prefix` variable for auto-generated unique S3 bucket names

## [1.0.0] - 2026-02-13

### Added
- Initial shared-services module with ECR repository and S3 artifact bucket
- Cross-account ECR access policies
- Artifact bucket with versioning and lifecycle rules
