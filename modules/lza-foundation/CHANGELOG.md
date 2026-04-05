# Changelog

All notable changes to this module are documented in this file.

## [1.8.0] - 2026-02-11

### Added
- IAM user for pipeline polling (status checks without assuming roles)

## [1.7.3] - 2026-02-07

### Fixed
- Escape shell variables in heredoc for CodeBuild update
- Wait for CodePipeline execution to complete

## [1.7.2] - 2026-02-07

### Fixed
- Variable setting for Lambda concurrency limit bypass

## [1.7.1] - 2026-02-07

### Fixed
- CodeBuild update-project JSON escaping

## [1.7.0] - 2026-02-06

### Removed
- Unused `platform_lza_access` IAM role
- API Gateway (no longer needed)

## [1.6.0] - 2026-02-04

### Added
- Lambda concurrency limit bypass for new accounts (avoids throttling during initial LZA deployment)

## [1.5.0] - 2026-01-23

### Removed
- `config_repo` variable (replaced by S3 config files)

## [1.4.0] - 2026-01-23

### Changed
- Switch from CodeCommit to S3 for LZA configuration files

## [1.3.0] - 2026-01-22

### Changed
- Updated CloudFormation parameters for LZA stack

## [1.2.0] - 2026-01-22

### Added
- `github_config_repo` variable for GitHub-based LZA config repository

## [1.1.0] - 2026-01-21

### Changed
- Pin to LZA release v1.14.2

## [1.0.5] - 2026-01-19

### Fixed
- Remove incorrect `RepositoryName` parameter

## [1.0.4] - 2026-01-19

### Changed
- Set `enable_approval_stage` default to `false`

## [1.0.3] - 2026-01-19

### Fixed
- Remove obsolete `EnableSingleAccountMode` and `ManagementAccountAccessRole` parameters

## [1.0.2] - 2026-01-19

### Fixed
- Add `ConfigurationRepositoryLocation` parameter required by latest LZA template

## [1.0.1] - 2026-01-19

### Fixed
- Update LZA template URL to `AWSAccelerator-InstallerStack.template`

## [1.0.0] - 2026-01-15

### Added
- Initial LZA foundation module for AWS Landing Zone Accelerator deployment
- CloudFormation stack management for LZA installer
- GitHub OIDC provider for CI/CD access
- Service-linked role creation
