output "storage_accounts" {
  description = "Map of storage account details"
  value = {
    for k, v in azurerm_storage_account.main : k => {
      id                          = v.id
      name                        = v.name
      primary_access_key          = v.primary_access_key
      primary_connection_string   = v.primary_connection_string
      primary_blob_endpoint       = v.primary_blob_endpoint
      secondary_access_key        = v.secondary_access_key
      secondary_connection_string = v.secondary_connection_string
      secondary_blob_endpoint     = v.secondary_blob_endpoint
    }
  }
  sensitive = true
}

output "storage_containers" {
  description = "Map of storage container details"
  value = {
    for k, v in azurerm_storage_container.main : k => {
      id   = v.id
      name = v.name
    }
  }
}
