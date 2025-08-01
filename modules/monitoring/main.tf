# Monitoring Module
# Creates and manages Log Analytics Workspace and Application Insights

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.cluster_name}-${var.environment}-law"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.log_analytics_workspace.sku
  retention_in_days   = var.log_analytics_workspace.retention_in_days
  daily_quota_gb      = var.log_analytics_workspace.daily_quota_gb

  tags = var.tags
}

# Log Analytics Solution for Container Insights
resource "azurerm_log_analytics_solution" "container_insights" {
  count = var.enable_container_insights ? 1 : 0

  solution_name         = "ContainerInsights"
  location              = var.location
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.main.id
  workspace_name        = azurerm_log_analytics_workspace.main.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }

  tags = var.tags
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                                  = "${var.cluster_name}-${var.environment}-ai"
  location                              = var.location
  resource_group_name                   = var.resource_group_name
  workspace_id                          = azurerm_log_analytics_workspace.main.id
  application_type                      = var.application_insights.application_type
  daily_data_cap_in_gb                  = var.application_insights.daily_data_cap_in_gb
  daily_data_cap_notifications_disabled = var.application_insights.daily_data_cap_notifications_disabled
  retention_in_days                     = var.application_insights.retention_in_days
  sampling_percentage                   = var.application_insights.sampling_percentage

  tags = var.tags
}
