# DNS Module
# Creates and manages Azure DNS Zones and Records

# Private DNS Zone for AKS
resource "azurerm_private_dns_zone" "aks" {
  count = var.enable_private_dns ? 1 : 0

  name                = var.private_dns_zone_name
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "aks" {
  count = var.enable_private_dns ? 1 : 0

  name                  = "${var.private_dns_zone_name}-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.aks[0].name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = var.enable_auto_registration

  tags = var.tags
}

# Public DNS Zone (optional)
resource "azurerm_dns_zone" "public" {
  count = var.enable_public_dns ? 1 : 0

  name                = var.public_dns_zone_name
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# DNS A Records for AKS API Server (if using private cluster)
resource "azurerm_private_dns_a_record" "aks_api" {
  count = var.enable_private_dns && var.aks_api_server_ip != null ? 1 : 0

  name                = var.aks_api_server_record_name
  zone_name           = azurerm_private_dns_zone.aks[0].name
  resource_group_name = var.resource_group_name
  ttl                 = var.dns_record_ttl
  records             = [var.aks_api_server_ip]

  tags = var.tags
}

# Custom DNS Records
resource "azurerm_private_dns_a_record" "custom_private" {
  for_each = var.enable_private_dns ? var.custom_private_dns_records : {}

  name                = each.value.name
  zone_name           = azurerm_private_dns_zone.aks[0].name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl
  records             = each.value.records

  tags = merge(var.tags, each.value.tags)
}

resource "azurerm_dns_a_record" "custom_public" {
  for_each = var.enable_public_dns ? var.custom_public_dns_records : {}

  name                = each.value.name
  zone_name           = azurerm_dns_zone.public[0].name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl
  records             = each.value.records

  tags = merge(var.tags, each.value.tags)
}

# CNAME Records for Public DNS
resource "azurerm_dns_cname_record" "custom_public_cname" {
  for_each = var.enable_public_dns ? var.custom_public_cname_records : {}

  name                = each.value.name
  zone_name           = azurerm_dns_zone.public[0].name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl
  record              = each.value.record

  tags = merge(var.tags, each.value.tags)
}

# DNS Zone for Container Registry (if using private endpoints)
resource "azurerm_private_dns_zone" "acr" {
  count = var.enable_acr_private_dns ? 1 : 0

  name                = "privatelink.azurecr.io"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  count = var.enable_acr_private_dns ? 1 : 0

  name                  = "acr-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.acr[0].name
  virtual_network_id    = var.virtual_network_id

  tags = var.tags
}

# DNS Zone for Key Vault (if using private endpoints)
resource "azurerm_private_dns_zone" "keyvault" {
  count = var.enable_keyvault_private_dns ? 1 : 0

  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "keyvault" {
  count = var.enable_keyvault_private_dns ? 1 : 0

  name                  = "keyvault-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault[0].name
  virtual_network_id    = var.virtual_network_id

  tags = var.tags
}

# DNS Zone for Storage Account (if using private endpoints)
resource "azurerm_private_dns_zone" "storage_blob" {
  count = var.enable_storage_private_dns ? 1 : 0

  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_blob" {
  count = var.enable_storage_private_dns ? 1 : 0

  name                  = "storage-blob-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage_blob[0].name
  virtual_network_id    = var.virtual_network_id

  tags = var.tags
}
