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

variable "storage_accounts" {
  description = "Map of storage accounts to create"
  type = map(object({
    # Required basic configuration
    account_tier              = string
    account_replication_type  = string
    
    # Optional basic configuration with defaults
    account_kind              = optional(string, "StorageV2")
    access_tier               = optional(string, "Hot")
    enable_https_traffic_only = optional(bool, true)
    min_tls_version           = optional(string, "TLS1_2")
    
    # Optional advanced configuration
    allow_nested_items_to_be_public   = optional(bool, false)
    shared_access_key_enabled         = optional(bool, true)
    public_network_access_enabled     = optional(bool, true)
    default_to_oauth_authentication   = optional(bool, false)
    cross_tenant_replication_enabled  = optional(bool, true)
    infrastructure_encryption_enabled = optional(bool, false)
    large_file_share_enabled          = optional(bool, false)
    nfsv3_enabled                     = optional(bool, false)
    is_hns_enabled                    = optional(bool, false)
    sftp_enabled                      = optional(bool, false)
    
    # Blob properties
    versioning_enabled               = optional(bool, true)
    delete_retention_days            = optional(number, 7)
    container_delete_retention_days  = optional(number, 7)

    # Identity configuration (optional)
    identity_type = optional(string, null)
    identity_ids  = optional(list(string), [])

    # Customer managed key (optional)
    customer_managed_key = optional(object({
      key_vault_key_id          = string
      user_assigned_identity_id = string
    }), null)

    # Network rules (optional)
    network_rules = optional(object({
      default_action             = string
      bypass                     = list(string)
      ip_rules                   = list(string)
      virtual_network_subnet_ids = list(string)
    }), null)

    # Containers (required for backward compatibility)
    containers = list(object({
      name                  = string
      container_access_type = string
      metadata              = optional(map(string), {})
    }))

    # File shares (optional)
    file_shares = optional(list(object({
      name             = string
      quota            = number
      enabled_protocol = optional(string, "SMB")
      metadata         = optional(map(string), {})
      access_tier      = optional(string, null)
    })), [])

    # Queues (optional)
    queues = optional(list(object({
      name     = string
      metadata = optional(map(string), {})
    })), [])

    # Tables (optional)
    tables = optional(list(object({
      name = string
    })), [])

    # Private endpoint configuration (optional)
    enable_private_endpoint         = optional(bool, false)
    private_endpoint_subresources   = optional(list(string), ["blob"])

    # Tags
    tags = optional(map(string), {})
  }))
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoints"
  type        = string
  default     = null
}

variable "blob_private_dns_zone_id" {
  description = "Private DNS zone ID for blob private endpoints"
  type        = string
  default     = null
}

variable "file_private_dns_zone_id" {
  description = "Private DNS zone ID for file private endpoints"
  type        = string
  default     = null
}

variable "enable_diagnostic_settings" {
  description = "Enable diagnostic settings for Storage Accounts"
  type        = bool
  default     = false
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
    "StorageRead",
    "StorageWrite",
    "StorageDelete"
  ]
}

variable "diagnostic_metrics" {
  description = "List of diagnostic metric categories to enable"
  type        = list(string)
  default = [
    "Transaction"
  ]
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}
