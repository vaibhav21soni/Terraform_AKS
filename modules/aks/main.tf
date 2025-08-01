# AKS Module
# Creates and manages Azure Kubernetes Service cluster and node pools

# AKS Cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.cluster_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.dns_prefix}-${var.environment}"
  kubernetes_version  = var.kubernetes_version
  sku_tier            = var.sku_tier
  private_cluster_enabled = var.private_cluster_enabled
  private_dns_zone_id = var.private_cluster_enabled ? var.private_dns_zone_id : null
  private_cluster_public_fqdn_enabled = var.private_cluster_public_fqdn_enabled

  default_node_pool {
    name            = var.default_node_pool.name
    vm_size         = var.default_node_pool.vm_size
    vnet_subnet_id  = var.vnet_subnet_id
    node_count      = var.default_node_pool.enable_auto_scaling ? null : var.default_node_pool.node_count
    min_count       = var.default_node_pool.enable_auto_scaling ? var.default_node_pool.min_count : null
    max_count       = var.default_node_pool.enable_auto_scaling ? var.default_node_pool.max_count : null
    max_pods        = var.default_node_pool.max_pods
    os_disk_size_gb = var.default_node_pool.os_disk_size_gb
    os_disk_type    = var.default_node_pool.os_disk_type
    type            = "VirtualMachineScaleSets"
    zones           = var.default_node_pool.availability_zones

    dynamic "upgrade_settings" {
      for_each = lookup(var.default_node_pool, "upgrade_settings", null) != null ? [var.default_node_pool.upgrade_settings] : []
      content {
        max_surge = upgrade_settings.value.max_surge
      }
    }

    tags = var.tags
  }

  identity {
    type         = "UserAssigned"
    identity_ids = var.identity_ids
  }

  network_profile {
    network_plugin      = var.network_plugin
    network_policy      = var.network_policy
    dns_service_ip      = var.dns_service_ip
    service_cidr        = var.service_cidr
    load_balancer_sku   = var.load_balancer_sku
    outbound_type       = var.outbound_type
    pod_cidr            = var.network_plugin == "kubenet" ? var.pod_cidr : null
    network_plugin_mode = var.network_plugin_mode

    dynamic "load_balancer_profile" {
      for_each = var.load_balancer_profile != null ? [var.load_balancer_profile] : []
      content {
        idle_timeout_in_minutes     = load_balancer_profile.value.idle_timeout_in_minutes
        managed_outbound_ip_count   = load_balancer_profile.value.managed_outbound_ip_count
        managed_outbound_ipv6_count = load_balancer_profile.value.managed_outbound_ipv6_count
        outbound_ip_address_ids     = load_balancer_profile.value.outbound_ip_address_ids
        outbound_ip_prefix_ids      = load_balancer_profile.value.outbound_ip_prefix_ids
        outbound_ports_allocated    = load_balancer_profile.value.outbound_ports_allocated
      }
    }

    dynamic "nat_gateway_profile" {
      for_each = var.nat_gateway_profile != null ? [var.nat_gateway_profile] : []
      content {
        idle_timeout_in_minutes   = nat_gateway_profile.value.idle_timeout_in_minutes
        managed_outbound_ip_count = nat_gateway_profile.value.managed_outbound_ip_count
      }
    }
  }

  dynamic "oms_agent" {
    for_each = var.log_analytics_workspace_id != null ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  azure_policy_enabled = var.azure_policy_enabled

  dynamic "key_vault_secrets_provider" {
    for_each = var.enable_key_vault_secrets_provider ? [1] : []
    content {
      secret_rotation_enabled  = true
      secret_rotation_interval = "2m"
    }
  }

  dynamic "microsoft_defender" {
    for_each = var.enable_microsoft_defender ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  workload_identity_enabled = var.enable_workload_identity
  oidc_issuer_enabled       = var.enable_oidc_issuer

  dynamic "auto_scaler_profile" {
    for_each = var.auto_scaler_profile != null ? [var.auto_scaler_profile] : []
    content {
      balance_similar_node_groups      = auto_scaler_profile.value.balance_similar_node_groups
      expander                         = auto_scaler_profile.value.expander
      max_graceful_termination_sec     = auto_scaler_profile.value.max_graceful_termination_sec
      max_node_provisioning_time       = auto_scaler_profile.value.max_node_provisioning_time
      max_unready_nodes                = auto_scaler_profile.value.max_unready_nodes
      max_unready_percentage           = auto_scaler_profile.value.max_unready_percentage
      new_pod_scale_up_delay           = auto_scaler_profile.value.new_pod_scale_up_delay
      scale_down_delay_after_add       = auto_scaler_profile.value.scale_down_delay_after_add
      scale_down_delay_after_delete    = auto_scaler_profile.value.scale_down_delay_after_delete
      scale_down_delay_after_failure   = auto_scaler_profile.value.scale_down_delay_after_failure
      scan_interval                    = auto_scaler_profile.value.scan_interval
      scale_down_unneeded              = auto_scaler_profile.value.scale_down_unneeded
      scale_down_unready               = auto_scaler_profile.value.scale_down_unready
      scale_down_utilization_threshold = auto_scaler_profile.value.scale_down_utilization_threshold
      empty_bulk_delete_max            = auto_scaler_profile.value.empty_bulk_delete_max
      skip_nodes_with_local_storage    = auto_scaler_profile.value.skip_nodes_with_local_storage
      skip_nodes_with_system_pods      = auto_scaler_profile.value.skip_nodes_with_system_pods
    }
  }

  tags = var.tags
}

# Additional Node Pools
resource "azurerm_kubernetes_cluster_node_pool" "additional" {
  for_each = var.additional_node_pools

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = each.value.vm_size
  vnet_subnet_id        = var.vnet_subnet_id
  node_count            = each.value.enable_auto_scaling ? null : each.value.node_count
  min_count             = each.value.enable_auto_scaling ? each.value.min_count : null
  max_count             = each.value.enable_auto_scaling ? each.value.max_count : null
  max_pods              = each.value.max_pods
  os_disk_size_gb       = each.value.os_disk_size_gb
  os_disk_type          = each.value.os_disk_type
  os_type               = each.value.os_type
  node_taints           = each.value.node_taints
  node_labels           = each.value.node_labels
  zones                 = each.value.availability_zones
  priority              = each.value.priority
  eviction_policy       = each.value.priority == "Spot" ? each.value.eviction_policy : null
  spot_max_price        = each.value.priority == "Spot" ? each.value.spot_max_price : null

  dynamic "upgrade_settings" {
    for_each = each.value.upgrade_settings != null ? [each.value.upgrade_settings] : []
    content {
      max_surge = upgrade_settings.value.max_surge
    }
  }

  tags = merge(var.tags, each.value.tags)
}

# Role Assignment for ACR
resource "azurerm_role_assignment" "aks_acr" {
  count = var.enable_acr_integration ? 1 : 0

  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = var.acr_id
  skip_service_principal_aad_check = true
}
