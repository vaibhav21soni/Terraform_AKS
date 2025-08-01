output "aks_identity_id" {
  description = "ID of the AKS user assigned identity"
  value       = azurerm_user_assigned_identity.aks.id
}

output "aks_identity_principal_id" {
  description = "Principal ID of the AKS user assigned identity"
  value       = azurerm_user_assigned_identity.aks.principal_id
}

output "aks_identity_client_id" {
  description = "Client ID of the AKS user assigned identity"
  value       = azurerm_user_assigned_identity.aks.client_id
}

output "additional_identities" {
  description = "Map of additional user assigned identities"
  value = {
    for k, v in azurerm_user_assigned_identity.additional : k => {
      id           = v.id
      principal_id = v.principal_id
      client_id    = v.client_id
    }
  }
}
