# Changelog

All notable changes to this module are documented in this file.

## [1.5.0] - 2026-03-27

### Added
- `application` variable for SSM path convention (`/{application}/{environment}/...`)
- `bucket_name` variable to prevent S3 bucket recreation on name changes
- `force_destroy` variable for S3 bucket teardown
- `domain_aliases` support for vanity domains on CloudFront

## [1.3.0] - 2026-03-08

### Changed
- Use `bucket_prefix` for auto-generated unique S3 bucket names

## [1.2.0] - 2026-03-07

### Changed
- Include AWS account ID in S3 bucket name for global uniqueness

## [1.1.0] - 2026-03-02

### Added
- CloudFront Function for directory URL rewriting (index.html resolution)

## [1.0.0] - 2026-02-25

### Added
- Initial static website module with S3, CloudFront, and ACM certificate
- Origin access control for S3
- Custom error page handling
