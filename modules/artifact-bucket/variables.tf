variable "bucket_name" {
  description = "Name of the S3 bucket for artifacts (e.g., client-slug-artifacts)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must be lowercase, start/end with letter or number, and contain only letters, numbers, hyphens, and periods."
  }
}

variable "organization_path" {
  description = "AWS Organizations path for cross-account read policy (e.g., o-abc123/r-root/ou-workloads)"
  type        = string
  default     = null
}

variable "enable_versioning" {
  description = "Enable S3 versioning for artifact history"
  type        = bool
  default     = true
}

variable "enable_lifecycle_policy" {
  description = "Enable lifecycle policy to clean up old artifact versions"
  type        = bool
  default     = true
}

variable "noncurrent_version_expiry_days" {
  description = "Days before noncurrent versions are deleted"
  type        = number
  default     = 90
}

variable "abort_incomplete_multipart_days" {
  description = "Days before incomplete multipart uploads are aborted"
  type        = number
  default     = 7
}

variable "force_destroy" {
  description = "Allow bucket to be destroyed even if it contains objects"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to the bucket"
  type        = map(string)
  default     = {}
}
