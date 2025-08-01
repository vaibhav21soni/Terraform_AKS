variable "environment" {
  description = "Environment name"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "key_vault_name" {
  description = "Name of the Key Vault"
  type        = string
}

variable "sku_name" {
  description = "The Name of the SKU used for this Key Vault"
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "SKU name must be either 'standard' or 'premium'."
  }
}

variable "enabled_for_deployment" {
  description = "Boolean flag to specify whether Azure Virtual Machines are permitted to retrieve certificates"
  type        = bool
  default     = false
}

variable "enabled_for_disk_encryption" {
  description = "Boolean flag to specify whether Azure Disk Encryption is permitted to retrieve secrets"
  type        = bool
  default     = false
}

variable "enabled_for_template_deployment" {
  description = "Boolean flag to specify whether Azure Resource Manager is permitted to retrieve secrets"
  type        = bool
  default     = false
}

variable "enable_rbac_authorization" {
  description = "Boolean flag to specify whether Azure Key Vault uses Role Based Access Control (RBAC) for authorization"
  type        = bool
  default     = false
}

variable "purge_protection_enabled" {
  description = "Is Purge Protection enabled for this Key Vault?"
  type        = bool
  default     = false
}

variable "soft_delete_retention_days" {
  description = "The number of days that items should be retained for once soft-deleted"
  type        = number
  default     = 90
  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "Soft delete retention days must be between 7 and 90."
  }
}

variable "public_network_access_enabled" {
  description = "Whether public network access is allowed for this Key Vault"
  type        = bool
  default     = true
}

variable "network_acls" {
  description = "Network ACLs for the Key Vault"
  type = object({
    default_action             = string
    bypass                     = string
    ip_rules                   = list(string)
    virtual_network_subnet_ids = list(string)
  })
  default = null
}

variable "access_policies" {
  description = "Map of access policies for the Key Vault (used when RBAC is disabled)"
  type = map(object({
    object_id               = string
    key_permissions         = list(string)
    secret_permissions      = list(string)
    certificate_permissions = list(string)
    storage_permissions     = list(string)
  }))
  default = {}
}

variable "rbac_assignments" {
  description = "Map of RBAC role assignments for the Key Vault (used when RBAC is enabled)"
  type = map(object({
    role_definition_name = string
    principal_id         = string
  }))
  default = {}
}

variable "secrets" {
  description = "Map of secrets to create in the Key Vault"
  type = map(object({
    value           = string
    content_type    = string
    expiration_date = string
    tags            = map(string)
  }))
  default = {}
}

variable "keys" {
  description = "Map of keys to create in the Key Vault"
  type = map(object({
    key_type        = string
    key_size        = number
    curve           = string
    key_opts        = list(string)
    expiration_date = string
    rotation_policy = object({
      time_after_creation  = string
      time_before_expiry   = string
      expire_after         = string
      notify_before_expiry = string
    })
    tags = map(string)
  }))
  default = {}
}

variable "certificates" {
  description = "Map of certificates to create in the Key Vault"
  type = map(object({
    certificate_policy = object({
      issuer_name         = string
      exportable          = bool
      key_size            = number
      key_type            = string
      reuse_key           = bool
      action_type         = string
      days_before_expiry  = number
      lifetime_percentage = number
      content_type        = string
      extended_key_usage  = list(string)
      key_usage           = list(string)
      subject             = string
      validity_in_months  = number
      subject_alternative_names = object({
        dns_names = list(string)
        emails    = list(string)
        upns      = list(string)
      })
    })
    tags = map(string)
  }))
  default = {}
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint for Key Vault"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for the private endpoint"
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID for the private endpoint"
  type        = string
  default     = null
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostic settings"
  type        = string
  default     = null
}

variable "diagnostic_logs" {
  description = "List of diagnostic log categories to enable"
  type        = list(string)
  default = [
    "AuditEvent",
    "AzurePolicyEvaluationDetails"
  ]
}

variable "diagnostic_metrics" {
  description = "List of diagnostic metric categories to enable"
  type        = list(string)
  default = [
    "AllMetrics"
  ]
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}
