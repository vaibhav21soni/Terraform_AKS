# Key Vault Module
# Creates and manages Azure Key Vault with secrets, keys, certificates, and access policies

# Get current client configuration
data "azurerm_client_config" "current" {}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                = "${var.key_vault_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = var.sku_name

  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment
  enable_rbac_authorization       = var.enable_rbac_authorization
  purge_protection_enabled        = var.purge_protection_enabled
  soft_delete_retention_days      = var.soft_delete_retention_days
  public_network_access_enabled   = var.public_network_access_enabled

  dynamic "network_acls" {
    for_each = var.network_acls != null ? [var.network_acls] : []
    content {
      default_action             = network_acls.value.default_action
      bypass                     = network_acls.value.bypass
      ip_rules                   = network_acls.value.ip_rules
      virtual_network_subnet_ids = network_acls.value.virtual_network_subnet_ids
    }
  }

  tags = var.tags
}

# Access Policies (when RBAC is not enabled)
resource "azurerm_key_vault_access_policy" "policies" {
  for_each = var.enable_rbac_authorization ? {} : var.access_policies

  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = each.value.object_id

  key_permissions         = each.value.key_permissions
  secret_permissions      = each.value.secret_permissions
  certificate_permissions = each.value.certificate_permissions
  storage_permissions     = each.value.storage_permissions
}

# Default access policy for current user/service principal
resource "azurerm_key_vault_access_policy" "current" {
  count = var.enable_rbac_authorization ? 0 : 1

  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import",
    "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update",
    "Verify", "WrapKey", "Release", "Rotate", "GetRotationPolicy", "SetRotationPolicy"
  ]

  secret_permissions = [
    "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"
  ]

  certificate_permissions = [
    "Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers",
    "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers",
    "Purge", "Recover", "Restore", "SetIssuers", "Update"
  ]

  storage_permissions = [
    "Backup", "Delete", "DeleteSAS", "Get", "GetSAS", "List", "ListSAS",
    "Purge", "Recover", "RegenerateKey", "Restore", "Set", "SetSAS", "Update"
  ]
}

# RBAC Role Assignments (when RBAC is enabled)
resource "azurerm_role_assignment" "rbac_assignments" {
  for_each = var.enable_rbac_authorization ? var.rbac_assignments : {}

  scope                = azurerm_key_vault.main.id
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
}

# Key Vault Secrets
resource "azurerm_key_vault_secret" "secrets" {
  for_each = var.secrets

  name         = each.key
  value        = each.value.value
  key_vault_id = azurerm_key_vault.main.id
  content_type = each.value.content_type
  expiration_date = each.value.expiration_date != null ? each.value.expiration_date : null

  tags = merge(var.tags, each.value.tags)

  depends_on = [
    azurerm_key_vault_access_policy.current,
    azurerm_key_vault_access_policy.policies,
    azurerm_role_assignment.rbac_assignments
  ]
}

# Key Vault Keys
resource "azurerm_key_vault_key" "keys" {
  for_each = var.keys

  name         = each.key
  key_vault_id = azurerm_key_vault.main.id
  key_type     = each.value.key_type
  key_size     = each.value.key_size
  curve        = each.value.curve
  key_opts     = each.value.key_opts
  expiration_date = each.value.expiration_date != null ? each.value.expiration_date : null

  dynamic "rotation_policy" {
    for_each = each.value.rotation_policy != null ? [each.value.rotation_policy] : []
    content {
      automatic {
        time_after_creation = rotation_policy.value.time_after_creation
        time_before_expiry  = rotation_policy.value.time_before_expiry
      }
      expire_after         = rotation_policy.value.expire_after
      notify_before_expiry = rotation_policy.value.notify_before_expiry
    }
  }

  tags = merge(var.tags, each.value.tags)

  depends_on = [
    azurerm_key_vault_access_policy.current,
    azurerm_key_vault_access_policy.policies,
    azurerm_role_assignment.rbac_assignments
  ]
}

# Key Vault Certificates
resource "azurerm_key_vault_certificate" "certificates" {
  for_each = var.certificates

  name         = each.key
  key_vault_id = azurerm_key_vault.main.id

  dynamic "certificate_policy" {
    for_each = [each.value.certificate_policy]
    content {
      issuer_parameters {
        name = certificate_policy.value.issuer_name
      }

      key_properties {
        exportable = certificate_policy.value.exportable
        key_size   = certificate_policy.value.key_size
        key_type   = certificate_policy.value.key_type
        reuse_key  = certificate_policy.value.reuse_key
      }

      lifetime_action {
        action {
          action_type = certificate_policy.value.action_type
        }

        trigger {
          days_before_expiry  = certificate_policy.value.days_before_expiry
          lifetime_percentage = certificate_policy.value.lifetime_percentage
        }
      }

      secret_properties {
        content_type = certificate_policy.value.content_type
      }

      x509_certificate_properties {
        extended_key_usage = certificate_policy.value.extended_key_usage
        key_usage          = certificate_policy.value.key_usage
        subject            = certificate_policy.value.subject
        validity_in_months = certificate_policy.value.validity_in_months

        dynamic "subject_alternative_names" {
          for_each = certificate_policy.value.subject_alternative_names != null ? [certificate_policy.value.subject_alternative_names] : []
          content {
            dns_names = subject_alternative_names.value.dns_names
            emails    = subject_alternative_names.value.emails
            upns      = subject_alternative_names.value.upns
          }
        }
      }
    }
  }

  tags = merge(var.tags, each.value.tags)

  depends_on = [
    azurerm_key_vault_access_policy.current,
    azurerm_key_vault_access_policy.policies,
    azurerm_role_assignment.rbac_assignments
  ]
}

# Private Endpoint for Key Vault
resource "azurerm_private_endpoint" "main" {
  count = var.enable_private_endpoint ? 1 : 0

  name                = "${var.key_vault_name}-${var.environment}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.key_vault_name}-${var.environment}-psc"
    private_connection_resource_id = azurerm_key_vault.main.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id != null ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }

  tags = var.tags
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "main" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "${var.key_vault_name}-${var.environment}-diag"
  target_resource_id         = azurerm_key_vault.main.id
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
