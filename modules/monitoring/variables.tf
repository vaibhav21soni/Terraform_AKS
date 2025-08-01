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

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "log_analytics_workspace" {
  description = "Log Analytics Workspace configuration"
  type = object({
    sku               = string
    retention_in_days = number
    daily_quota_gb    = number
  })
}

variable "application_insights" {
  description = "Application Insights configuration"
  type = object({
    application_type                      = string
    daily_data_cap_in_gb                  = number
    daily_data_cap_notifications_disabled = bool
    retention_in_days                     = number
    sampling_percentage                   = number
  })
}

variable "enable_container_insights" {
  description = "Enable Container Insights solution"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}
