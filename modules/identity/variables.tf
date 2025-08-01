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

variable "vnet_id" {
  description = "ID of the virtual network for role assignments"
  type        = string
  default     = ""
}

variable "enable_network_contributor_role" {
  description = "Enable Network Contributor role for AKS identity"
  type        = bool
  default     = true
}

variable "identities" {
  description = "Map of additional user assigned identities to create"
  type = map(object({
    tags = map(string)
    role_assignments = list(object({
      role_definition_name = string
      scope                = string
    }))
  }))
  default = {}
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}
