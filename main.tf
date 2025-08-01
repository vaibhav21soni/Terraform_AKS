# Root Module - Main Configuration
# This file orchestrates all the sub-modules for different resource types

# Data sources
data "azurerm_client_config" "current" {}

# Resource Group Module
module "resource_group" {
  source = "./modules/resource-group"

  for_each = var.environments

  environment         = each.key
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  tags                = merge(local.common_tags, each.value.tags, { Environment = each.key })
}

# Networking Module
module "networking" {
  source = "./modules/networking"

  for_each = var.environments

  environment                   = each.key
  resource_group_name           = module.resource_group[each.key].name
  location                      = module.resource_group[each.key].location
  cluster_name                  = each.value.cluster_name
  vnet_address_space            = each.value.networking.vnet_address_space
  aks_subnet_address_prefixes   = each.value.networking.aks_subnet_address_prefixes
  appgw_subnet_address_prefixes = each.value.networking.appgw_subnet_address_prefixes
  enable_application_gateway    = each.value.networking.enable_application_gateway
  enable_nat_gateway            = each.value.networking.enable_nat_gateway
  network_security_rules        = each.value.networking.network_security_rules
  tags                          = merge(local.common_tags, each.value.tags, { Environment = each.key })

  depends_on = [module.resource_group]
}

# Identity Module
module "identity" {
  source = "./modules/identity"

  for_each = var.environments

  environment                     = each.key
  resource_group_name             = module.resource_group[each.key].name
  location                        = module.resource_group[each.key].location
  cluster_name                    = each.value.cluster_name
  vnet_id                         = module.networking[each.key].vnet_id
  enable_network_contributor_role = true
  identities                      = each.value.identities
  tags                            = merge(local.common_tags, each.value.tags, { Environment = each.key })

  depends_on = [module.resource_group, module.networking]
}

# Container Registry Module
module "container_registry" {
  source = "./modules/container-registry"

  for_each = { for k, v in var.environments : k => v if v.container_registry.enabled }

  environment                   = each.key
  resource_group_name           = module.resource_group[each.key].name
  location                      = module.resource_group[each.key].location
  acr_name                      = each.value.container_registry.name
  acr_sku                       = each.value.container_registry.sku
  admin_enabled                 = each.value.container_registry.admin_enabled
  public_network_access_enabled = each.value.container_registry.public_network_access_enabled
  quarantine_policy_enabled     = each.value.container_registry.quarantine_policy_enabled
  georeplication_locations      = each.value.container_registry.georeplication_locations
  network_rule_set              = each.value.container_registry.network_rule_set

  # Enhanced configurations with defaults
  identity_type                   = lookup(each.value.container_registry, "identity_type", null)
  identity_ids                    = lookup(each.value.container_registry, "identity_ids", [])
  encryption_enabled              = lookup(each.value.container_registry, "encryption_enabled", false)
  encryption_key_vault_key_id     = lookup(each.value.container_registry, "encryption_key_vault_key_id", null)
  encryption_identity_client_id   = lookup(each.value.container_registry, "encryption_identity_client_id", null)
  anonymous_pull_enabled          = lookup(each.value.container_registry, "anonymous_pull_enabled", false)
  data_endpoint_enabled           = lookup(each.value.container_registry, "data_endpoint_enabled", false)
  network_rule_bypass_option      = lookup(each.value.container_registry, "network_rule_bypass_option", "AzureServices")

  # Private endpoint configuration
  enable_private_endpoint         = lookup(each.value.container_registry, "enable_private_endpoint", false)
  private_endpoint_subnet_id      = lookup(each.value.container_registry, "enable_private_endpoint", false) ? module.networking[each.key].aks_subnet_id : null
  private_dns_zone_id             = lookup(each.value.container_registry, "enable_private_endpoint", false) && lookup(each.value, "dns", null) != null ? try(module.dns[each.key].acr_private_dns_zone_id, null) : null

  # ACR Tasks and webhooks
  acr_tasks                       = lookup(each.value.container_registry, "acr_tasks", {})
  webhooks                        = lookup(each.value.container_registry, "webhooks", {})

  # Monitoring
  enable_diagnostic_settings     = lookup(each.value.container_registry, "enable_diagnostic_settings", false)
  log_analytics_workspace_id     = lookup(each.value.container_registry, "enable_diagnostic_settings", false) ? module.monitoring[each.key].log_analytics_workspace_id : null

  tags = merge(local.common_tags, each.value.tags, { Environment = each.key })

  depends_on = [module.resource_group, module.networking, module.monitoring]
}

# Storage Module
module "storage" {
  source = "./modules/storage"

  for_each = var.environments

  environment         = each.key
  resource_group_name = module.resource_group[each.key].name
  location            = module.resource_group[each.key].location
  storage_accounts    = each.value.storage_accounts

  # Private endpoint configuration
  private_endpoint_subnet_id = module.networking[each.key].aks_subnet_id
  blob_private_dns_zone_id   = lookup(each.value, "dns", null) != null ? try(module.dns[each.key].storage_private_dns_zone_id, null) : null
  file_private_dns_zone_id   = lookup(each.value, "dns", null) != null ? try(module.dns[each.key].storage_private_dns_zone_id, null) : null

  # Monitoring
  enable_diagnostic_settings = lookup(each.value, "enable_storage_diagnostic_settings", false)
  log_analytics_workspace_id = lookup(each.value, "enable_storage_diagnostic_settings", false) ? module.monitoring[each.key].log_analytics_workspace_id : null

  tags = merge(local.common_tags, each.value.tags, { Environment = each.key })

  depends_on = [module.resource_group, module.networking, module.monitoring]
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"

  for_each = var.environments

  environment               = each.key
  resource_group_name       = module.resource_group[each.key].name
  location                  = module.resource_group[each.key].location
  cluster_name              = each.value.cluster_name
  log_analytics_workspace   = each.value.monitoring.log_analytics_workspace
  application_insights      = each.value.monitoring.application_insights
  enable_container_insights = each.value.monitoring.enable_container_insights
  tags                      = merge(local.common_tags, each.value.tags, { Environment = each.key })

  depends_on = [module.resource_group]
}

# AKS Module (depends on most other modules)
module "aks" {
  source = "./modules/aks"

  for_each = var.environments

  environment         = each.key
  resource_group_name = module.resource_group[each.key].name
  location            = module.resource_group[each.key].location
  cluster_name        = each.value.cluster_name
  dns_prefix          = each.value.dns_prefix
  kubernetes_version  = each.value.aks.kubernetes_version
  sku_tier            = each.value.aks.sku_tier

  # Network configuration
  vnet_subnet_id = module.networking[each.key].aks_subnet_id
  network_plugin = each.value.aks.network_plugin
  network_policy = each.value.aks.network_policy
  dns_service_ip = each.value.aks.dns_service_ip
  service_cidr   = each.value.aks.service_cidr

  # Private cluster and DNS configuration
  private_cluster_enabled             = lookup(each.value.aks, "private_cluster_enabled", false)
  private_dns_zone_id                 = lookup(each.value.aks, "private_cluster_enabled", false) && lookup(each.value, "dns", null) != null ? module.dns[each.key].private_dns_zone_id : null
  private_cluster_public_fqdn_enabled = lookup(each.value.aks, "private_cluster_public_fqdn_enabled", false)

  # Load balancer configuration
  load_balancer_sku     = lookup(each.value.aks, "load_balancer_sku", "standard")
  outbound_type         = lookup(each.value.aks, "outbound_type", "loadBalancer")
  pod_cidr              = lookup(each.value.aks, "pod_cidr", null)
  network_plugin_mode   = lookup(each.value.aks, "network_plugin_mode", null)
  load_balancer_profile = lookup(each.value.aks, "load_balancer_profile", null)
  nat_gateway_profile   = lookup(each.value.aks, "nat_gateway_profile", null)

  # Identity configuration
  identity_ids = [module.identity[each.key].aks_identity_id]

  # Node pools
  default_node_pool     = each.value.aks.default_node_pool
  additional_node_pools = each.value.aks.additional_node_pools

  # Add-ons and features
  azure_policy_enabled              = each.value.aks.azure_policy_enabled
  enable_key_vault_secrets_provider = each.value.aks.enable_key_vault_secrets_provider
  enable_microsoft_defender         = each.value.aks.enable_microsoft_defender
  enable_workload_identity          = each.value.aks.enable_workload_identity
  enable_oidc_issuer                = each.value.aks.enable_oidc_issuer

  # Auto scaler profile
  auto_scaler_profile = each.value.aks.auto_scaler_profile

  # Monitoring
  log_analytics_workspace_id = module.monitoring[each.key].log_analytics_workspace_id

  # Container Registry
  enable_acr_integration = lookup(each.value, "container_registry", {}) != {} && lookup(each.value.container_registry, "enabled", false)
  acr_id = lookup(each.value, "container_registry", {}) != {} && lookup(each.value.container_registry, "enabled", false) ? try(module.container_registry[each.key].acr_id, null) : null

  tags = merge(local.common_tags, each.value.tags, { Environment = each.key })

  depends_on = [
    module.resource_group,
    module.networking,
    module.identity,
    module.monitoring,
    module.container_registry
  ]
}

# DNS Module
module "dns" {
  source = "./modules/dns"

  for_each = {
    for env_key, env_config in var.environments : env_key => env_config
    if lookup(env_config, "dns", null) != null
  }

  resource_group_name = module.resource_group[each.key].name
  virtual_network_id  = module.networking[each.key].vnet_id

  # DNS Configuration
  enable_private_dns              = lookup(each.value.dns, "enable_private_dns", true)
  enable_public_dns               = lookup(each.value.dns, "enable_public_dns", false)
  enable_acr_private_dns          = lookup(each.value.dns, "enable_acr_private_dns", false)
  enable_keyvault_private_dns     = lookup(each.value.dns, "enable_keyvault_private_dns", false)
  enable_storage_private_dns      = lookup(each.value.dns, "enable_storage_private_dns", false)
  
  private_dns_zone_name           = lookup(each.value.dns, "private_dns_zone_name", "privatelink.${each.value.location}.azmk8s.io")
  public_dns_zone_name            = lookup(each.value.dns, "public_dns_zone_name", null)
  enable_auto_registration        = lookup(each.value.dns, "enable_auto_registration", false)
  
  aks_api_server_ip               = lookup(each.value.dns, "aks_api_server_ip", null)
  aks_api_server_record_name      = lookup(each.value.dns, "aks_api_server_record_name", "api")
  
  custom_private_dns_records      = lookup(each.value.dns, "custom_private_dns_records", {})
  custom_public_dns_records       = lookup(each.value.dns, "custom_public_dns_records", {})
  custom_public_cname_records     = lookup(each.value.dns, "custom_public_cname_records", {})

  tags = merge(local.common_tags, each.value.tags, { Environment = each.key })

  depends_on = [module.networking]
}

# Key Vault Module
module "key_vault" {
  source = "./modules/key-vault"

  for_each = {
    for env_key, env_config in var.environments : env_key => env_config
    if lookup(env_config, "key_vault", null) != null
  }

  environment         = each.key
  resource_group_name = module.resource_group[each.key].name
  location            = module.resource_group[each.key].location
  key_vault_name      = each.value.key_vault.name

  # Key Vault Configuration
  sku_name                        = lookup(each.value.key_vault, "sku_name", "standard")
  enabled_for_deployment          = lookup(each.value.key_vault, "enabled_for_deployment", false)
  enabled_for_disk_encryption     = lookup(each.value.key_vault, "enabled_for_disk_encryption", false)
  enabled_for_template_deployment = lookup(each.value.key_vault, "enabled_for_template_deployment", false)
  enable_rbac_authorization       = lookup(each.value.key_vault, "enable_rbac_authorization", false)
  purge_protection_enabled        = lookup(each.value.key_vault, "purge_protection_enabled", false)
  soft_delete_retention_days      = lookup(each.value.key_vault, "soft_delete_retention_days", 90)
  public_network_access_enabled   = lookup(each.value.key_vault, "public_network_access_enabled", true)

  # Network and Access Configuration
  network_acls                    = lookup(each.value.key_vault, "network_acls", null)
  access_policies                 = lookup(each.value.key_vault, "access_policies", {})
  rbac_assignments                = lookup(each.value.key_vault, "rbac_assignments", {})

  # Secrets, Keys, and Certificates
  secrets                         = lookup(each.value.key_vault, "secrets", {})
  keys                            = lookup(each.value.key_vault, "keys", {})
  certificates                    = lookup(each.value.key_vault, "certificates", {})

  # Private Endpoint Configuration
  enable_private_endpoint         = lookup(each.value.key_vault, "enable_private_endpoint", false)
  private_endpoint_subnet_id      = lookup(each.value.key_vault, "enable_private_endpoint", false) ? module.networking[each.key].aks_subnet_id : null
  private_dns_zone_id             = lookup(each.value.key_vault, "enable_private_endpoint", false) && lookup(each.value, "dns", null) != null ? module.dns[each.key].keyvault_private_dns_zone_id : null

  # Monitoring
  log_analytics_workspace_id      = module.monitoring[each.key].log_analytics_workspace_id

  tags = merge(local.common_tags, each.value.tags, { Environment = each.key })

  depends_on = [module.resource_group, module.networking, module.monitoring]
}

# Load Balancer Module
module "load_balancer" {
  source = "./modules/load-balancer"

  for_each = {
    for env_key, env_config in var.environments : env_key => env_config
    if lookup(env_config, "load_balancers", null) != null
  }

  environment         = each.key
  resource_group_name = module.resource_group[each.key].name
  location            = module.resource_group[each.key].location

  load_balancers = each.value.load_balancers

  tags = merge(local.common_tags, each.value.tags, { Environment = each.key })

  depends_on = [module.resource_group, module.networking]
}
