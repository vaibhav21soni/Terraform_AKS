# Storage Module
# Creates and manages Azure Storage Accounts and Containers

resource "azurerm_storage_account" "main" {
  for_each = var.storage_accounts

  name                      = lower(replace("${each.key}${var.environment}${random_string.suffix[each.key].result}", "-", ""))
  resource_group_name       = var.resource_group_name
  location                  = var.location
  account_tier              = each.value.account_tier
  account_replication_type  = each.value.account_replication_type
  account_kind              = lookup(each.value, "account_kind", "StorageV2")
  access_tier               = lookup(each.value, "access_tier", "Hot")
  https_traffic_only_enabled = lookup(each.value, "enable_https_traffic_only", true)
  min_tls_version           = lookup(each.value, "min_tls_version", "TLS1_2")
  
  # Optional advanced features with defaults
  allow_nested_items_to_be_public   = lookup(each.value, "allow_nested_items_to_be_public", false)
  shared_access_key_enabled         = lookup(each.value, "shared_access_key_enabled", true)
  public_network_access_enabled     = lookup(each.value, "public_network_access_enabled", true)
  default_to_oauth_authentication   = lookup(each.value, "default_to_oauth_authentication", false)
  cross_tenant_replication_enabled  = lookup(each.value, "cross_tenant_replication_enabled", true)
  infrastructure_encryption_enabled = lookup(each.value, "infrastructure_encryption_enabled", false)
  large_file_share_enabled          = lookup(each.value, "large_file_share_enabled", false)
  nfsv3_enabled                     = lookup(each.value, "nfsv3_enabled", false)
  is_hns_enabled                    = lookup(each.value, "is_hns_enabled", false)
  sftp_enabled                      = lookup(each.value, "sftp_enabled", false)

  dynamic "network_rules" {
    for_each = lookup(each.value, "network_rules", null) != null ? [each.value.network_rules] : []
    content {
      default_action             = network_rules.value.default_action
      bypass                     = network_rules.value.bypass
      ip_rules                   = network_rules.value.ip_rules
      virtual_network_subnet_ids = network_rules.value.virtual_network_subnet_ids
    }
  }

  # Basic blob properties
  blob_properties {
    versioning_enabled = lookup(each.value, "versioning_enabled", true)
    
    delete_retention_policy {
      days = lookup(each.value, "delete_retention_days", 7)
    }
    
    container_delete_retention_policy {
      days = lookup(each.value, "container_delete_retention_days", 7)
    }
  }

  # Identity configuration (optional)
  dynamic "identity" {
    for_each = lookup(each.value, "identity_type", null) != null ? [1] : []
    content {
      type         = each.value.identity_type
      identity_ids = lookup(each.value, "identity_type", null) == "UserAssigned" ? lookup(each.value, "identity_ids", []) : null
    }
  }

  # Customer managed key (optional)
  dynamic "customer_managed_key" {
    for_each = lookup(each.value, "customer_managed_key", null) != null ? [each.value.customer_managed_key] : []
    content {
      key_vault_key_id          = customer_managed_key.value.key_vault_key_id
      user_assigned_identity_id = customer_managed_key.value.user_assigned_identity_id
    }
  }

  tags = merge(var.tags, lookup(each.value, "tags", {}))
}

# Storage Containers
resource "azurerm_storage_container" "main" {
  for_each = {
    for container in flatten([
      for sa_key, sa_config in var.storage_accounts : [
        for container in lookup(sa_config, "containers", []) : {
          key                   = "${sa_key}-${container.name}"
          storage_account_name  = azurerm_storage_account.main[sa_key].name
          name                  = container.name
          container_access_type = container.container_access_type
          metadata              = lookup(container, "metadata", {})
        }
      ]
    ]) : container.key => container
  }

  name                  = each.value.name
  storage_account_name  = each.value.storage_account_name
  container_access_type = each.value.container_access_type
  metadata              = each.value.metadata
}

# File Shares (optional)
resource "azurerm_storage_share" "main" {
  for_each = {
    for share in flatten([
      for sa_key, sa_config in var.storage_accounts : [
        for share in lookup(sa_config, "file_shares", []) : {
          key                  = "${sa_key}-${share.name}"
          storage_account_name = azurerm_storage_account.main[sa_key].name
          name                 = share.name
          quota                = share.quota
          enabled_protocol     = lookup(share, "enabled_protocol", "SMB")
          metadata             = lookup(share, "metadata", {})
          access_tier          = lookup(share, "access_tier", null)
        }
      ]
    ]) : share.key => share
  }

  name                 = each.value.name
  storage_account_name = each.value.storage_account_name
  quota                = each.value.quota
  enabled_protocol     = each.value.enabled_protocol
  metadata             = each.value.metadata
  access_tier          = each.value.access_tier
}

# Queues (optional)
resource "azurerm_storage_queue" "main" {
  for_each = {
    for queue in flatten([
      for sa_key, sa_config in var.storage_accounts : [
        for queue in lookup(sa_config, "queues", []) : {
          key                  = "${sa_key}-${queue.name}"
          storage_account_name = azurerm_storage_account.main[sa_key].name
          name                 = queue.name
          metadata             = lookup(queue, "metadata", {})
        }
      ]
    ]) : queue.key => queue
  }

  name                 = each.value.name
  storage_account_name = each.value.storage_account_name
  metadata             = each.value.metadata
}

# Tables (optional)
resource "azurerm_storage_table" "main" {
  for_each = {
    for table in flatten([
      for sa_key, sa_config in var.storage_accounts : [
        for table in lookup(sa_config, "tables", []) : {
          key                  = "${sa_key}-${table.name}"
          storage_account_name = azurerm_storage_account.main[sa_key].name
          name                 = table.name
        }
      ]
    ]) : table.key => table
  }

  name                 = each.value.name
  storage_account_name = each.value.storage_account_name
}

# Private Endpoints (optional)
resource "azurerm_private_endpoint" "blob" {
  for_each = {
    for sa_key, sa_config in var.storage_accounts : sa_key => sa_config
    if lookup(sa_config, "enable_private_endpoint", false) && contains(lookup(sa_config, "private_endpoint_subresources", ["blob"]), "blob")
  }

  name                = "${each.key}-${var.environment}-blob-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${each.key}-${var.environment}-blob-psc"
    private_connection_resource_id = azurerm_storage_account.main[each.key].id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = var.blob_private_dns_zone_id != null ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = [var.blob_private_dns_zone_id]
    }
  }

  tags = var.tags
}

resource "azurerm_private_endpoint" "file" {
  for_each = {
    for sa_key, sa_config in var.storage_accounts : sa_key => sa_config
    if lookup(sa_config, "enable_private_endpoint", false) && contains(lookup(sa_config, "private_endpoint_subresources", ["file"]), "file")
  }

  name                = "${each.key}-${var.environment}-file-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${each.key}-${var.environment}-file-psc"
    private_connection_resource_id = azurerm_storage_account.main[each.key].id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = var.file_private_dns_zone_id != null ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = [var.file_private_dns_zone_id]
    }
  }

  tags = var.tags
}

# Diagnostic Settings (optional)
resource "azurerm_monitor_diagnostic_setting" "main" {
  for_each = var.enable_diagnostic_settings ? var.storage_accounts : {}

  name                       = "${each.key}-${var.environment}-diag"
  target_resource_id         = azurerm_storage_account.main[each.key].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = var.diagnostic_logs
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = var.diagnostic_metrics
    content {
      category = metric.value
      enabled  = true
    }
  }
}

resource "random_string" "suffix" {
  for_each = var.storage_accounts

  length  = 4
  special = false
  upper   = false
}
