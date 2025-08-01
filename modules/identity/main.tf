# Identity Module
# Creates and manages Azure User Assigned Identities and Role Assignments

# User Assigned Identity for AKS
resource "azurerm_user_assigned_identity" "aks" {
  name                = "${var.cluster_name}-${var.environment}-identity"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Additional User Assigned Identities
resource "azurerm_user_assigned_identity" "additional" {
  for_each = var.identities

  name                = "${var.cluster_name}-${var.environment}-${each.key}-identity"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = merge(var.tags, each.value.tags)
}

# Role Assignments for AKS Identity
resource "azurerm_role_assignment" "aks_network_contributor" {
  count = var.enable_network_contributor_role ? 1 : 0

  principal_id                     = azurerm_user_assigned_identity.aks.principal_id
  role_definition_name             = "Network Contributor"
  scope                            = var.vnet_id
  skip_service_principal_aad_check = true
}

# Role Assignments for Additional Identities
resource "azurerm_role_assignment" "additional" {
  for_each = {
    for assignment in flatten([
      for identity_key, identity_config in var.identities : [
        for role in identity_config.role_assignments : {
          identity_key = identity_key
          role_name    = role.role_definition_name
          scope        = role.scope
          key          = "${identity_key}-${role.role_definition_name}"
        }
      ]
    ]) : assignment.key => assignment
  }

  principal_id                     = azurerm_user_assigned_identity.additional[each.value.identity_key].principal_id
  role_definition_name             = each.value.role_name
  scope                            = each.value.scope
  skip_service_principal_aad_check = true
}
