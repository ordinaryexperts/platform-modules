variable "name" {
  description = "Name of the ECR repository (e.g., client-slug/app-name)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9/_-]*$", var.name))
    error_message = "Repository name must start with lowercase letter or number and contain only lowercase letters, numbers, hyphens, underscores, and forward slashes."
  }
}

variable "image_tag_mutability" {
  description = "Tag mutability setting. MUTABLE allows overwriting tags, IMMUTABLE prevents it."
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "Image tag mutability must be MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "Enable vulnerability scanning when images are pushed"
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "Encryption type for the repository (AES256 or KMS)"
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "Encryption type must be AES256 or KMS."
  }
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption (required if encryption_type is KMS)"
  type        = string
  default     = null
}

variable "organization_path" {
  description = "AWS Organizations path for cross-account pull policy (e.g., o-abc123/r-root/ou-workloads)"
  type        = string
  default     = null
}

variable "enable_lifecycle_policy" {
  description = "Enable lifecycle policy to clean up untagged images"
  type        = bool
  default     = true
}

variable "untagged_image_expiry_days" {
  description = "Days to keep untagged images before deletion"
  type        = number
  default     = 30
}

variable "max_image_count" {
  description = "Maximum number of tagged images to keep (0 = unlimited)"
  type        = number
  default     = 0
}

variable "tags" {
  description = "Tags to apply to the repository"
  type        = map(string)
  default     = {}
}
