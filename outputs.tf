# Root Module Outputs
# Outputs for all environments and resources

# Environment-specific outputs
output "environments" {
  description = "Map of all environment configurations and their resource details"
  value = {
    for env_name, env_config in var.environments : env_name => {
      # Resource Group
      resource_group = {
        id       = module.resource_group[env_name].id
        name     = module.resource_group[env_name].name
        location = module.resource_group[env_name].location
      }

      # Networking
      networking = {
        vnet_id                   = module.networking[env_name].vnet_id
        vnet_name                 = module.networking[env_name].vnet_name
        aks_subnet_id             = module.networking[env_name].aks_subnet_id
        aks_subnet_name           = module.networking[env_name].aks_subnet_name
        appgw_subnet_id           = module.networking[env_name].appgw_subnet_id
        nat_gateway_id            = module.networking[env_name].nat_gateway_id
        nat_gateway_public_ip     = module.networking[env_name].nat_gateway_public_ip
        route_table_id            = module.networking[env_name].route_table_id
        network_security_group_id = module.networking[env_name].network_security_group_id
      }

      # Identity
      identity = {
        aks_identity_id           = module.identity[env_name].aks_identity_id
        aks_identity_principal_id = module.identity[env_name].aks_identity_principal_id
        aks_identity_client_id    = module.identity[env_name].aks_identity_client_id
        additional_identities     = module.identity[env_name].additional_identities
      }

      # AKS
      aks = {
        cluster_id             = module.aks[env_name].cluster_id
        cluster_name           = module.aks[env_name].cluster_name
        cluster_fqdn           = module.aks[env_name].cluster_fqdn
        cluster_endpoint       = module.aks[env_name].cluster_endpoint
        cluster_ca_certificate = module.aks[env_name].cluster_ca_certificate
        kube_config            = module.aks[env_name].kube_config
        kubelet_identity       = module.aks[env_name].kubelet_identity
        node_resource_group    = module.aks[env_name].node_resource_group
        oidc_issuer_url        = module.aks[env_name].oidc_issuer_url
        additional_node_pools  = module.aks[env_name].additional_node_pools
      }

      # Container Registry
      container_registry = env_config.container_registry.enabled ? {
        acr_id         = module.container_registry[env_name].acr_id
        acr_name       = module.container_registry[env_name].acr_name
        login_server   = module.container_registry[env_name].login_server
        admin_username = module.container_registry[env_name].admin_username
        admin_password = module.container_registry[env_name].admin_password
      } : null

      # Storage
      storage = {
        storage_accounts   = module.storage[env_name].storage_accounts
        storage_containers = module.storage[env_name].storage_containers
      }

      # Monitoring
      monitoring = {
        log_analytics_workspace_id                 = module.monitoring[env_name].log_analytics_workspace_id
        log_analytics_workspace_name               = module.monitoring[env_name].log_analytics_workspace_name
        log_analytics_workspace_workspace_id       = module.monitoring[env_name].log_analytics_workspace_workspace_id
        log_analytics_workspace_primary_shared_key = module.monitoring[env_name].log_analytics_workspace_primary_shared_key
        application_insights_id                    = module.monitoring[env_name].application_insights_id
        application_insights_app_id                = module.monitoring[env_name].application_insights_app_id
        application_insights_instrumentation_key   = module.monitoring[env_name].application_insights_instrumentation_key
        application_insights_connection_string     = module.monitoring[env_name].application_insights_connection_string
      }
    }
  }
  sensitive = true
}

# Quick access outputs for common use cases
output "aks_clusters" {
  description = "Map of AKS cluster details for all environments"
  value = {
    for env_name in keys(var.environments) : env_name => {
      cluster_name   = module.aks[env_name].cluster_name
      cluster_fqdn   = module.aks[env_name].cluster_fqdn
      resource_group = module.resource_group[env_name].name
    }
  }
}

output "container_registries" {
  description = "Map of Container Registry details for environments where enabled"
  value = {
    for env_name, env_config in var.environments : env_name => {
      login_server = env_config.container_registry.enabled ? module.container_registry[env_name].login_server : null
      acr_name     = env_config.container_registry.enabled ? module.container_registry[env_name].acr_name : null
    } if env_config.container_registry.enabled
  }
}

output "monitoring_workspaces" {
  description = "Map of Log Analytics workspace details for all environments"
  value = {
    for env_name in keys(var.environments) : env_name => {
      workspace_id   = module.monitoring[env_name].log_analytics_workspace_id
      workspace_name = module.monitoring[env_name].log_analytics_workspace_name
    }
  }
}

# Kubectl configuration commands
output "kubectl_commands" {
  description = "Commands to configure kubectl for each environment"
  value = {
    for env_name in keys(var.environments) : env_name =>
    "az aks get-credentials --resource-group ${module.resource_group[env_name].name} --name ${module.aks[env_name].cluster_name}"
  }
}

# Resource counts per environment
output "resource_summary" {
  description = "Summary of resources created per environment"
  value = {
    for env_name, env_config in var.environments : env_name => {
      resource_group_count     = 1
      aks_cluster_count        = 1
      node_pool_count          = 1 + length(env_config.aks.additional_node_pools)
      storage_account_count    = length(env_config.storage_accounts)
      container_registry_count = env_config.container_registry.enabled ? 1 : 0
    }
  }
}

# Environment validation results
output "validation_results" {
  description = "Validation results for each environment configuration"
  value       = local.validation_results
}

# Feature flags per environment
output "feature_flags" {
  description = "Feature flags enabled per environment"
  value       = local.feature_flags
}

# Current workspace information
output "current_workspace" {
  description = "Current Terraform workspace"
  value       = terraform.workspace
}
