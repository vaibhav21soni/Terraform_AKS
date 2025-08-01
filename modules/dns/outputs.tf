output "private_dns_zone_id" {
  description = "ID of the private DNS zone"
  value       = var.enable_private_dns ? azurerm_private_dns_zone.aks[0].id : null
}

output "private_dns_zone_name" {
  description = "Name of the private DNS zone"
  value       = var.enable_private_dns ? azurerm_private_dns_zone.aks[0].name : null
}

output "public_dns_zone_id" {
  description = "ID of the public DNS zone"
  value       = var.enable_public_dns ? azurerm_dns_zone.public[0].id : null
}

output "public_dns_zone_name" {
  description = "Name of the public DNS zone"
  value       = var.enable_public_dns ? azurerm_dns_zone.public[0].name : null
}

output "public_dns_zone_name_servers" {
  description = "Name servers for the public DNS zone"
  value       = var.enable_public_dns ? azurerm_dns_zone.public[0].name_servers : []
}

output "acr_private_dns_zone_id" {
  description = "ID of the ACR private DNS zone"
  value       = var.enable_acr_private_dns ? azurerm_private_dns_zone.acr[0].id : null
}

output "keyvault_private_dns_zone_id" {
  description = "ID of the Key Vault private DNS zone"
  value       = var.enable_keyvault_private_dns ? azurerm_private_dns_zone.keyvault[0].id : null
}

output "storage_private_dns_zone_id" {
  description = "ID of the Storage private DNS zone"
  value       = var.enable_storage_private_dns ? azurerm_private_dns_zone.storage_blob[0].id : null
}

output "private_dns_zone_virtual_network_link_id" {
  description = "ID of the private DNS zone virtual network link"
  value       = var.enable_private_dns ? azurerm_private_dns_zone_virtual_network_link.aks[0].id : null
}

output "custom_private_dns_records" {
  description = "Map of custom private DNS A records"
  value = {
    for k, v in azurerm_private_dns_a_record.custom_private : k => {
      id      = v.id
      name    = v.name
      fqdn    = v.fqdn
      records = v.records
    }
  }
}

output "custom_public_dns_records" {
  description = "Map of custom public DNS A records"
  value = {
    for k, v in azurerm_dns_a_record.custom_public : k => {
      id      = v.id
      name    = v.name
      fqdn    = v.fqdn
      records = v.records
    }
  }
}

output "custom_public_cname_records" {
  description = "Map of custom public DNS CNAME records"
  value = {
    for k, v in azurerm_dns_cname_record.custom_public_cname : k => {
      id     = v.id
      name   = v.name
      fqdn   = v.fqdn
      record = v.record
    }
  }
}
