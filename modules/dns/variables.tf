variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "virtual_network_id" {
  description = "ID of the virtual network to link DNS zones to"
  type        = string
}

variable "enable_private_dns" {
  description = "Enable private DNS zone for AKS"
  type        = bool
  default     = true
}

variable "enable_public_dns" {
  description = "Enable public DNS zone"
  type        = bool
  default     = false
}

variable "enable_acr_private_dns" {
  description = "Enable private DNS zone for Azure Container Registry"
  type        = bool
  default     = false
}

variable "enable_keyvault_private_dns" {
  description = "Enable private DNS zone for Key Vault"
  type        = bool
  default     = false
}

variable "enable_storage_private_dns" {
  description = "Enable private DNS zone for Storage Account"
  type        = bool
  default     = false
}

variable "private_dns_zone_name" {
  description = "Name of the private DNS zone for AKS"
  type        = string
  default     = "privatelink.eastus.azmk8s.io"
}

variable "public_dns_zone_name" {
  description = "Name of the public DNS zone"
  type        = string
  default     = null
}

variable "enable_auto_registration" {
  description = "Enable auto registration for private DNS zone"
  type        = bool
  default     = false
}

variable "aks_api_server_ip" {
  description = "IP address of the AKS API server (for private clusters)"
  type        = string
  default     = null
}

variable "aks_api_server_record_name" {
  description = "DNS record name for AKS API server"
  type        = string
  default     = "api"
}

variable "dns_record_ttl" {
  description = "TTL for DNS records"
  type        = number
  default     = 300
}

variable "custom_private_dns_records" {
  description = "Map of custom private DNS A records"
  type = map(object({
    name    = string
    records = list(string)
    ttl     = number
    tags    = map(string)
  }))
  default = {}
}

variable "custom_public_dns_records" {
  description = "Map of custom public DNS A records"
  type = map(object({
    name    = string
    records = list(string)
    ttl     = number
    tags    = map(string)
  }))
  default = {}
}

variable "custom_public_cname_records" {
  description = "Map of custom public DNS CNAME records"
  type = map(object({
    name   = string
    record = string
    ttl    = number
    tags   = map(string)
  }))
  default = {}
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}
