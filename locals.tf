# Local values for computed configurations and dynamic resource management

locals {
  # Common tags that will be applied to all resources
  common_tags = merge(
    var.global_tags,
    {
      CreatedDate = formatdate("YYYY-MM-DD", timestamp())
      Terraform   = "true"
      Workspace   = terraform.workspace
    }
  )

  # Environment-specific configurations
  environments = var.environments

  # Flatten environments for easier iteration
  environment_list = keys(var.environments)

  # Resource naming conventions
  naming_convention = {
    separator = "-"
    prefix    = "aks"
  }

  # Network configuration validation
  network_validation = {
    for env_name, env_config in var.environments : env_name => {
      vnet_valid           = length(env_config.networking.vnet_address_space) > 0
      aks_subnet_valid     = length(env_config.networking.aks_subnet_address_prefixes) > 0
      service_cidr_valid   = env_config.aks.service_cidr != null && env_config.aks.service_cidr != ""
      dns_service_ip_valid = env_config.aks.dns_service_ip != null && env_config.aks.dns_service_ip != ""
    }
  }

  # Conditional resource creation flags
  resource_flags = {
    for env_name, env_config in var.environments : env_name => {
      create_acr                = env_config.container_registry.enabled
      create_nat_gateway        = env_config.networking.enable_nat_gateway
      create_app_gateway_subnet = env_config.networking.enable_application_gateway
    }
  }

  # Storage account configurations with dynamic naming
  storage_configs = {
    for env_name, env_config in var.environments : env_name => {
      for sa_name, sa_config in env_config.storage_accounts : sa_name => merge(sa_config, {
        full_name = lower(replace("${sa_name}${env_name}${random_string.storage_suffix[env_name].result}", "-", ""))
      })
    }
  }

  # ACR configurations with dynamic naming
  acr_configs = {
    for env_name, env_config in var.environments : env_name => merge(env_config.container_registry, {
      full_name = lower(replace("${env_config.container_registry.name}${env_name}${random_string.acr_suffix[env_name].result}", "-", ""))
    }) if env_config.container_registry.enabled
  }

  # Node pool configurations with validation
  node_pool_configs = {
    for env_name, env_config in var.environments : env_name => {
      default = env_config.aks.default_node_pool
      additional = {
        for pool_name, pool_config in env_config.aks.additional_node_pools : pool_name => merge(pool_config, {
          validated_name = can(regex("^[a-z][a-z0-9]{0,11}$", pool_name)) ? pool_name : "pool${substr(md5(pool_name), 0, 8)}"
        })
      }
    }
  }

  # Environment-specific resource counts
  resource_counts = {
    for env_name, env_config in var.environments : env_name => {
      storage_accounts      = length(env_config.storage_accounts)
      additional_node_pools = length(env_config.aks.additional_node_pools)
      identities            = length(env_config.identities)
    }
  }

  # Monitoring configurations
  monitoring_configs = {
    for env_name, env_config in var.environments : env_name => {
      log_analytics_name        = "${env_config.cluster_name}-${env_name}-law"
      app_insights_name         = "${env_config.cluster_name}-${env_name}-ai"
      enable_container_insights = env_config.monitoring.enable_container_insights
    }
  }

  # Security configurations
  security_configs = {
    for env_name, env_config in var.environments : env_name => {
      network_security_enabled = length(env_config.networking.network_security_rules) > 0
      acr_network_restricted   = env_config.container_registry.enabled && !env_config.container_registry.public_network_access_enabled
    }
  }

  # Validation results
  validation_results = {
    for env_name, env_config in var.environments : env_name => {
      cluster_name_valid        = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{0,62}[a-zA-Z0-9]$", env_config.cluster_name))
      dns_prefix_valid          = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{0,62}[a-zA-Z0-9]$", env_config.dns_prefix))
      resource_group_name_valid = can(regex("^[a-zA-Z0-9._()-]{1,90}$", env_config.resource_group_name))
      location_valid            = env_config.location != null && env_config.location != ""
    }
  }

  # Feature flags per environment
  feature_flags = {
    for env_name, env_config in var.environments : env_name => {
      azure_policy               = env_config.aks.azure_policy_enabled
      key_vault_secrets_provider = env_config.aks.enable_key_vault_secrets_provider
      microsoft_defender         = env_config.aks.enable_microsoft_defender
      workload_identity          = env_config.aks.enable_workload_identity
      oidc_issuer                = env_config.aks.enable_oidc_issuer
      container_insights         = env_config.monitoring.enable_container_insights
    }
  }

  # Environment-specific configurations
  environment_config = {
    for env_name, env_config in var.environments : env_name => {
      node_count   = env_config.aks.default_node_pool.node_count
      vm_size      = env_config.aks.default_node_pool.vm_size
      auto_scaling = env_config.aks.default_node_pool.enable_auto_scaling
    }
  }
}

# Random strings for unique resource naming
resource "random_string" "storage_suffix" {
  for_each = var.environments

  length  = 4
  special = false
  upper   = false
}

resource "random_string" "acr_suffix" {
  for_each = { for k, v in var.environments : k => v if v.container_registry.enabled }

  length  = 4
  special = false
  upper   = false
}
