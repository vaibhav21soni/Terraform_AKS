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

variable "acr_name" {
  description = "Name of the Azure Container Registry"
  type        = string
}

variable "acr_sku" {
  description = "SKU for the Azure Container Registry"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "ACR SKU must be Basic, Standard, or Premium."
  }
}

variable "admin_enabled" {
  description = "Enable admin user for ACR"
  type        = bool
  default     = false
}

variable "georeplication_locations" {
  description = "List of geo-replication locations"
  type = list(object({
    location                = string
    zone_redundancy_enabled = bool
    tags                    = map(string)
  }))
  default = []
}

variable "network_rule_set" {
  description = "Network rule set configuration"
  type = object({
    default_action = string
    ip_rules = list(object({
      action   = string
      ip_range = string
    }))
    virtual_networks = list(object({
      action    = string
      subnet_id = string
    }))
  })
  default = null
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = true
}

variable "quarantine_policy_enabled" {
  description = "Enable quarantine policy"
  type        = bool
  default     = false
}

variable "identity_type" {
  description = "Type of identity for the registry"
  type        = string
  default     = null
  validation {
    condition     = var.identity_type == null || contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], var.identity_type)
    error_message = "Identity type must be SystemAssigned, UserAssigned, or SystemAssigned, UserAssigned."
  }
}

variable "identity_ids" {
  description = "List of user assigned identity IDs"
  type        = list(string)
  default     = []
}

variable "encryption_enabled" {
  description = "Enable encryption with customer-managed keys"
  type        = bool
  default     = false
}

variable "encryption_key_vault_key_id" {
  description = "Key Vault key ID for encryption"
  type        = string
  default     = null
}

variable "encryption_identity_client_id" {
  description = "Client ID of the identity for encryption"
  type        = string
  default     = null
}

variable "anonymous_pull_enabled" {
  description = "Enable anonymous pull access"
  type        = bool
  default     = false
}

variable "data_endpoint_enabled" {
  description = "Enable data endpoint"
  type        = bool
  default     = false
}

variable "network_rule_bypass_option" {
  description = "Network rule bypass option"
  type        = string
  default     = "AzureServices"
  validation {
    condition     = contains(["AzureServices", "None"], var.network_rule_bypass_option)
    error_message = "Network rule bypass option must be AzureServices or None."
  }
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint for the registry"
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

variable "enable_diagnostic_settings" {
  description = "Enable diagnostic settings for Container Registry"
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
    "ContainerRegistryRepositoryEvents",
    "ContainerRegistryLoginEvents"
  ]
}

variable "diagnostic_metrics" {
  description = "List of diagnostic metric categories to enable"
  type        = list(string)
  default = [
    "AllMetrics"
  ]
}

variable "acr_tasks" {
  description = "Map of ACR tasks to create"
  type = map(object({
    enabled = bool
    platform = object({
      os           = string
      architecture = string
      variant      = string
    })
    docker_step = object({
      dockerfile_path      = string
      context_path         = string
      context_access_token = string
      image_names          = list(string)
      cache_enabled        = bool
      push_enabled         = bool
      target               = string
      arguments            = map(string)
      secret_arguments     = map(string)
    })
    source_triggers = list(object({
      name           = string
      repository_url = string
      source_type    = string
      branch         = string
      events         = list(string)
      authentication = object({
        token             = string
        token_type        = string
        expire_in_seconds = number
        scope             = string
        refresh_token     = string
      })
    }))
    base_image_trigger = object({
      name                        = string
      type                        = string
      enabled                     = bool
      update_trigger_endpoint     = string
      update_trigger_payload_type = string
    })
    timer_triggers = list(object({
      name     = string
      schedule = string
      enabled  = bool
    }))
    identity_type = string
    identity_ids  = list(string)
    tags          = map(string)
  }))
  default = {}
}

variable "webhooks" {
  description = "Map of webhooks to create"
  type = map(object({
    service_uri    = string
    status         = string
    scope          = string
    actions        = list(string)
    custom_headers = map(string)
    tags           = map(string)
  }))
  default = {}
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}
