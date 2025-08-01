# Root Module Variables
# Defines variables for multi-environment AKS deployment

variable "environments" {
  description = "Map of environments and their configurations"
  type = map(object({
    # Basic Configuration
    resource_group_name = string
    location            = string
    cluster_name        = string
    dns_prefix          = string
    tags                = map(string)

    # Networking Configuration
    networking = object({
      vnet_address_space            = list(string)
      aks_subnet_address_prefixes   = list(string)
      appgw_subnet_address_prefixes = list(string)
      enable_application_gateway    = bool
      enable_nat_gateway            = bool
      network_security_rules = list(object({
        name                       = string
        priority                   = number
        direction                  = string
        access                     = string
        protocol                   = string
        source_port_range          = string
        destination_port_range     = string
        source_address_prefix      = string
        destination_address_prefix = string
      }))
    })

    # Identity Configuration
    identities = map(object({
      tags = map(string)
      role_assignments = list(object({
        role_definition_name = string
        scope                = string
      }))
    }))

    # AKS Configuration
    aks = object({
      kubernetes_version                = string
      sku_tier                          = string
      network_plugin                    = string
      network_policy                    = string
      dns_service_ip                    = string
      service_cidr                      = string
      azure_policy_enabled              = bool
      enable_key_vault_secrets_provider = bool
      enable_microsoft_defender         = bool
      enable_workload_identity          = bool
      enable_oidc_issuer                = bool

      # Default Node Pool
      default_node_pool = object({
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
        upgrade_settings = object({
          max_surge = string
        })
      })

      # Additional Node Pools
      additional_node_pools = map(object({
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

      # Auto Scaler Profile
      auto_scaler_profile = object({
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
    })

    # Container Registry Configuration
    container_registry = object({
      enabled                       = bool
      name                          = string
      sku                           = string
      admin_enabled                 = bool
      public_network_access_enabled = bool
      quarantine_policy_enabled     = bool
      retention_policy_enabled      = bool
      retention_policy_days         = number
      trust_policy_enabled          = bool
      georeplication_locations = list(object({
        location                = string
        zone_redundancy_enabled = bool
        tags                    = map(string)
      }))
      network_rule_set = object({
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
    })

    # Storage Configuration
    storage_accounts = map(object({
      account_tier              = string
      account_replication_type  = string
      account_kind              = string
      access_tier               = string
      enable_https_traffic_only = bool
      min_tls_version           = string
      containers = list(object({
        name                  = string
        container_access_type = string
      }))
      network_rules = object({
        default_action             = string
        bypass                     = list(string)
        ip_rules                   = list(string)
        virtual_network_subnet_ids = list(string)
      })
      tags = map(string)
    }))

    # Monitoring Configuration
    monitoring = object({
      log_analytics_workspace = object({
        sku               = string
        retention_in_days = number
        daily_quota_gb    = number
      })
      application_insights = object({
        application_type                      = string
        daily_data_cap_in_gb                  = number
        daily_data_cap_notifications_disabled = bool
        retention_in_days                     = number
        sampling_percentage                   = number
      })
      enable_container_insights = bool
    })
  }))
}

variable "global_tags" {
  description = "Global tags to be applied to all resources"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
    Project   = "AKS-Multi-Environment"
  }
}

# Backend configuration variables
variable "backend_config" {
  description = "Backend configuration for Terraform state"
  type = object({
    resource_group_name  = string
    storage_account_name = string
    container_name       = string
    key_prefix           = string
  })
  default = {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterraformstate"
    container_name       = "tfstate"
    key_prefix           = "aks"
  }
}
