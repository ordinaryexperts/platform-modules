# LZA Foundation Module - Variables

# Required Variables
variable "management_account_email" {
  description = "Email address for the management account root user"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.management_account_email))
    error_message = "Must be a valid email address."
  }
}

variable "log_archive_account_email" {
  description = "Email address for the log archive account root user"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.log_archive_account_email))
    error_message = "Must be a valid email address."
  }
}

variable "audit_account_email" {
  description = "Email address for the audit account root user"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.audit_account_email))
    error_message = "Must be a valid email address."
  }
}

variable "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider for role assumption"
  type        = string
}

variable "platform_github_org" {
  description = "GitHub organization that hosts the Platform (for role trust)"
  type        = string
  default     = "ordinaryexperts"
}

# Optional Variables with Defaults
variable "accelerator_prefix" {
  description = "Prefix for all LZA resources (must be lowercase)"
  type        = string
  default     = "lza"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.accelerator_prefix))
    error_message = "Prefix must start with a letter and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "lza_template_url" {
  description = "URL to the LZA CloudFormation installer template"
  type        = string
  default     = "https://s3.amazonaws.com/solutions-reference/landing-zone-accelerator-on-aws/latest/AWSAccelerator-Installer.template"
}

variable "control_tower_enabled" {
  description = "Whether AWS Control Tower is enabled in this account"
  type        = bool
  default     = false
}

variable "enable_single_account_mode" {
  description = "Enable single account mode (for testing/dev)"
  type        = bool
  default     = false
}

variable "repository_name" {
  description = "Name of the CodeCommit repository for LZA configuration"
  type        = string
  default     = "lza-config"
}

variable "repository_branch_name" {
  description = "Branch name for LZA configuration repository"
  type        = string
  default     = "main"
}

variable "enable_approval_stage" {
  description = "Enable manual approval stage in CodePipeline"
  type        = bool
  default     = true
}

variable "approval_stage_notify_email" {
  description = "Email to notify for pipeline approvals"
  type        = string
  default     = ""
}

variable "management_account_access_role" {
  description = "Name of the IAM role to assume in member accounts"
  type        = string
  default     = "AWSControlTowerExecution"
}

variable "create_platform_api" {
  description = "Create API Gateway for Platform integration"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Organizational Unit Structure
variable "organizational_units" {
  description = "List of organizational units to create"
  type = list(object({
    name     = string
    path     = string
    children = optional(list(string), [])
  }))
  default = [
    {
      name     = "Security"
      path     = "Root"
      children = []
    },
    {
      name     = "Infrastructure"
      path     = "Root"
      children = ["Dev", "Prod"]
    },
    {
      name     = "Workloads"
      path     = "Root"
      children = ["Dev", "Stage", "Prod"]
    },
    {
      name     = "Sandbox"
      path     = "Root"
      children = []
    }
  ]
}
