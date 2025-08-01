# Container Registry Module
# Creates and manages Azure Container Registry

resource "azurerm_container_registry" "main" {
  name                = "${var.acr_name}${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.acr_sku
  admin_enabled       = var.admin_enabled

  dynamic "georeplications" {
    for_each = var.georeplication_locations
    content {
      location                = georeplications.value.location
      zone_redundancy_enabled = georeplications.value.zone_redundancy_enabled
      tags                    = merge(var.tags, georeplications.value.tags)
    }
  }

  dynamic "network_rule_set" {
    for_each = var.network_rule_set != null ? [var.network_rule_set] : []
    content {
      default_action = network_rule_set.value.default_action

      dynamic "ip_rule" {
        for_each = network_rule_set.value.ip_rules
        content {
          action   = ip_rule.value.action
          ip_range = ip_rule.value.ip_range
        }
      }

      dynamic "virtual_network" {
        for_each = network_rule_set.value.virtual_networks
        content {
          action    = virtual_network.value.action
          subnet_id = virtual_network.value.subnet_id
        }
      }
    }
  }

  public_network_access_enabled = var.public_network_access_enabled
  quarantine_policy_enabled     = var.quarantine_policy_enabled

  # Identity for ACR Tasks and other features
  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" ? var.identity_ids : null
    }
  }

  # Encryption configuration
  dynamic "encryption" {
    for_each = var.encryption_enabled ? [1] : []
    content {
      key_vault_key_id   = var.encryption_key_vault_key_id
      identity_client_id = var.encryption_identity_client_id
    }
  }

  # Anonymous pull access
  anonymous_pull_enabled = var.anonymous_pull_enabled

  # Data endpoint enabled
  data_endpoint_enabled = var.data_endpoint_enabled

  # Network rule bypass
  network_rule_bypass_option = var.network_rule_bypass_option

  tags = var.tags
}

# Private Endpoint for Container Registry
resource "azurerm_private_endpoint" "main" {
  count = var.enable_private_endpoint ? 1 : 0

  name                = "${var.acr_name}-${var.environment}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.acr_name}-${var.environment}-psc"
    private_connection_resource_id = azurerm_container_registry.main.id
    subresource_names              = ["registry"]
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

  name                       = "${var.acr_name}-${var.environment}-diag"
  target_resource_id         = azurerm_container_registry.main.id
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

# ACR Tasks (optional)
resource "azurerm_container_registry_task" "main" {
  for_each = var.acr_tasks

  name                  = each.key
  container_registry_id = azurerm_container_registry.main.id
  enabled               = each.value.enabled

  dynamic "platform" {
    for_each = [each.value.platform]
    content {
      os           = platform.value.os
      architecture = platform.value.architecture
      variant      = platform.value.variant
    }
  }

  dynamic "docker_step" {
    for_each = each.value.docker_step != null ? [each.value.docker_step] : []
    content {
      dockerfile_path      = docker_step.value.dockerfile_path
      context_path         = docker_step.value.context_path
      context_access_token = docker_step.value.context_access_token
      image_names          = docker_step.value.image_names
      cache_enabled        = docker_step.value.cache_enabled
      push_enabled         = docker_step.value.push_enabled
      target               = docker_step.value.target
      arguments            = docker_step.value.arguments
      secret_arguments     = docker_step.value.secret_arguments
    }
  }

  dynamic "source_trigger" {
    for_each = each.value.source_triggers
    content {
      name           = source_trigger.value.name
      repository_url = source_trigger.value.repository_url
      source_type    = source_trigger.value.source_type
      branch         = source_trigger.value.branch
      events         = source_trigger.value.events

      dynamic "authentication" {
        for_each = source_trigger.value.authentication != null ? [source_trigger.value.authentication] : []
        content {
          token      = authentication.value.token
          token_type = authentication.value.token_type
          expire_in_seconds = authentication.value.expire_in_seconds
          scope      = authentication.value.scope
          refresh_token = authentication.value.refresh_token
        }
      }
    }
  }

  dynamic "base_image_trigger" {
    for_each = each.value.base_image_trigger != null ? [each.value.base_image_trigger] : []
    content {
      name                        = base_image_trigger.value.name
      type                        = base_image_trigger.value.type
      enabled                     = base_image_trigger.value.enabled
      update_trigger_endpoint     = base_image_trigger.value.update_trigger_endpoint
      update_trigger_payload_type = base_image_trigger.value.update_trigger_payload_type
    }
  }

  dynamic "timer_trigger" {
    for_each = each.value.timer_triggers
    content {
      name     = timer_trigger.value.name
      schedule = timer_trigger.value.schedule
      enabled  = timer_trigger.value.enabled
    }
  }

  dynamic "identity" {
    for_each = each.value.identity_type != null ? [1] : []
    content {
      type         = each.value.identity_type
      identity_ids = each.value.identity_type == "UserAssigned" ? each.value.identity_ids : null
    }
  }

  tags = merge(var.tags, each.value.tags)
}

# Webhook (optional)
resource "azurerm_container_registry_webhook" "main" {
  for_each = var.webhooks

  name                = each.key
  resource_group_name = var.resource_group_name
  registry_name       = azurerm_container_registry.main.name
  location            = var.location

  service_uri    = each.value.service_uri
  status         = each.value.status
  scope          = each.value.scope
  actions        = each.value.actions
  custom_headers = each.value.custom_headers

  tags = merge(var.tags, each.value.tags)
}
