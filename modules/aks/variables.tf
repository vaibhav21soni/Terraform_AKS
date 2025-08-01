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

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Version of Kubernetes to use for the AKS cluster"
  type        = string
  default     = null
}

variable "sku_tier" {
  description = "The SKU Tier that should be used for this Kubernetes Cluster"
  type        = string
  default     = "Free"
  validation {
    condition     = contains(["Free", "Paid"], var.sku_tier)
    error_message = "SKU tier must be either 'Free' or 'Paid'."
  }
}

variable "vnet_subnet_id" {
  description = "ID of the subnet for AKS nodes"
  type        = string
}

variable "identity_ids" {
  description = "List of User Assigned Identity IDs"
  type        = list(string)
}

variable "network_plugin" {
  description = "Network plugin to use for networking"
  type        = string
  default     = "azure"
  validation {
    condition     = contains(["azure", "kubenet"], var.network_plugin)
    error_message = "Network plugin must be either 'azure' or 'kubenet'."
  }
}

variable "network_policy" {
  description = "Network policy to use"
  type        = string
  default     = "azure"
  validation {
    condition     = contains(["azure", "calico", "cilium"], var.network_policy)
    error_message = "Network policy must be 'azure', 'calico', or 'cilium'."
  }
}

variable "dns_service_ip" {
  description = "IP address within the Kubernetes service address range"
  type        = string
  default     = null
}

variable "service_cidr" {
  description = "The Network Range used by the Kubernetes service"
  type        = string
  default     = null
}

variable "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  type        = string
  default     = null
}

variable "azure_policy_enabled" {
  description = "Enable Azure Policy for AKS"
  type        = bool
  default     = false
}

variable "enable_key_vault_secrets_provider" {
  description = "Enable Key Vault Secrets Provider"
  type        = bool
  default     = false
}

variable "enable_microsoft_defender" {
  description = "Enable Microsoft Defender for AKS"
  type        = bool
  default     = false
}

variable "enable_workload_identity" {
  description = "Enable Workload Identity"
  type        = bool
  default     = false
}

variable "enable_oidc_issuer" {
  description = "Enable OIDC Issuer"
  type        = bool
  default     = false
}

variable "enable_acr_integration" {
  description = "Enable ACR integration with AKS"
  type        = bool
  default     = false
}

variable "acr_id" {
  description = "ID of the Azure Container Registry"
  type        = string
  default     = null
}

variable "default_node_pool" {
  description = "Configuration for the default node pool"
  type = object({
    name                = string
    node_count          = number
    vm_size             = string
    enable_auto_scaling = bool
    min_count           = number
    max_count           = number
    max_pods            = number
    os_disk_size_gb     = number
    os_disk_type        = string
    availability_zones  = list(string)
    upgrade_settings = optional(object({
      max_surge = string
    }), null)
  })
}

variable "additional_node_pools" {
  description = "Map of additional node pools to create"
  type = map(object({
    vm_size             = string
    node_count          = number
    enable_auto_scaling = bool
    min_count           = number
    max_count           = number
    max_pods            = number
    os_disk_size_gb     = number
    os_disk_type        = string
    os_type             = string
    node_taints         = list(string)
    node_labels         = map(string)
    availability_zones  = list(string)
    priority            = string
    eviction_policy     = string
    spot_max_price      = number
    tags                = map(string)
    upgrade_settings = object({
      max_surge = string
    })
  }))
  default = {}
}

variable "auto_scaler_profile" {
  description = "Auto scaler profile configuration"
  type = object({
    balance_similar_node_groups      = bool
    expander                         = string
    max_graceful_termination_sec     = string
    max_node_provisioning_time       = string
    max_unready_nodes                = number
    max_unready_percentage           = number
    new_pod_scale_up_delay           = string
    scale_down_delay_after_add       = string
    scale_down_delay_after_delete    = string
    scale_down_delay_after_failure   = string
    scan_interval                    = string
    scale_down_unneeded              = string
    scale_down_unready               = string
    scale_down_utilization_threshold = number
    empty_bulk_delete_max            = number
    skip_nodes_with_local_storage    = bool
    skip_nodes_with_system_pods      = bool
  })
  default = null
}

variable "private_cluster_enabled" {
  description = "Enable private cluster"
  type        = bool
  default     = false
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID for private cluster"
  type        = string
  default     = null
}

variable "private_cluster_public_fqdn_enabled" {
  description = "Enable public FQDN for private cluster"
  type        = bool
  default     = false
}

variable "load_balancer_sku" {
  description = "SKU of the load balancer"
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["basic", "standard"], var.load_balancer_sku)
    error_message = "Load balancer SKU must be either 'basic' or 'standard'."
  }
}

variable "outbound_type" {
  description = "The outbound (egress) routing method"
  type        = string
  default     = "loadBalancer"
  validation {
    condition     = contains(["loadBalancer", "userDefinedRouting", "managedNATGateway", "userAssignedNATGateway"], var.outbound_type)
    error_message = "Outbound type must be one of: loadBalancer, userDefinedRouting, managedNATGateway, userAssignedNATGateway."
  }
}

variable "pod_cidr" {
  description = "The CIDR to use for pod IP addresses (kubenet only)"
  type        = string
  default     = null
}

variable "network_plugin_mode" {
  description = "Network plugin mode"
  type        = string
  default     = null
  validation {
    condition     = var.network_plugin_mode == null || contains(["overlay"], var.network_plugin_mode)
    error_message = "Network plugin mode must be 'overlay' or null."
  }
}

variable "load_balancer_profile" {
  description = "Load balancer profile configuration"
  type = object({
    idle_timeout_in_minutes     = number
    managed_outbound_ip_count   = number
    managed_outbound_ipv6_count = number
    outbound_ip_address_ids     = list(string)
    outbound_ip_prefix_ids      = list(string)
    outbound_ports_allocated    = number
  })
  default = null
}

variable "nat_gateway_profile" {
  description = "NAT Gateway profile configuration"
  type = object({
    idle_timeout_in_minutes   = number
    managed_outbound_ip_count = number
  })
  default = null
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}
