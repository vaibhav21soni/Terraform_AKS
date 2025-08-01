output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.main.id
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "key_vault_tenant_id" {
  description = "Tenant ID of the Key Vault"
  value       = azurerm_key_vault.main.tenant_id
}

output "secrets" {
  description = "Map of created secrets"
  value = {
    for k, v in azurerm_key_vault_secret.secrets : k => {
      id           = v.id
      name         = v.name
      version      = v.version
      versionless_id = v.versionless_id
    }
  }
  sensitive = true
}

output "keys" {
  description = "Map of created keys"
  value = {
    for k, v in azurerm_key_vault_key.keys : k => {
      id           = v.id
      name         = v.name
      version      = v.version
      versionless_id = v.versionless_id
      public_key_pem = v.public_key_pem
      public_key_openssh = v.public_key_openssh
    }
  }
}

output "certificates" {
  description = "Map of created certificates"
  value = {
    for k, v in azurerm_key_vault_certificate.certificates : k => {
      id                = v.id
      name              = v.name
      version           = v.version
      versionless_id    = v.versionless_id
      secret_id         = v.secret_id
      certificate_data  = v.certificate_data
      thumbprint        = v.thumbprint
    }
  }
  sensitive = true
}

output "private_endpoint_id" {
  description = "ID of the private endpoint"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.main[0].id : null
}

output "private_endpoint_ip_address" {
  description = "Private IP address of the private endpoint"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.main[0].private_service_connection[0].private_ip_address : null
}

output "private_endpoint_fqdn" {
  description = "FQDN of the private endpoint"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.main[0].custom_dns_configs[0].fqdn : null
}

output "access_policies" {
  description = "Map of access policies"
  value = {
    for k, v in azurerm_key_vault_access_policy.policies : k => {
      id        = v.id
      object_id = v.object_id
    }
  }
}

output "rbac_assignments" {
  description = "Map of RBAC role assignments"
  value = {
    for k, v in azurerm_role_assignment.rbac_assignments : k => {
      id                   = v.id
      principal_id         = v.principal_id
      role_definition_name = v.role_definition_name
    }
  }
}

output "diagnostic_setting_id" {
  description = "ID of the diagnostic setting"
  value       = var.log_analytics_workspace_id != null ? azurerm_monitor_diagnostic_setting.main[0].id : null
}
