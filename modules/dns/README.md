# DNS Module

This module creates and manages Azure DNS zones and records for the AKS infrastructure, including private DNS zones for private endpoints and public DNS zones for external access.

## Features

- **Private DNS Zones**: For AKS, ACR, Key Vault, and Storage Account private endpoints
- **Public DNS Zones**: For external DNS resolution
- **Custom DNS Records**: Support for custom A and CNAME records
- **Virtual Network Linking**: Automatic linking of private DNS zones to VNets
- **Auto Registration**: Optional auto-registration for private DNS zones

## Resources Created

- `azurerm_private_dns_zone` - Private DNS zones for various services
- `azurerm_dns_zone` - Public DNS zone (optional)
- `azurerm_private_dns_zone_virtual_network_link` - Links private DNS zones to VNet
- `azurerm_private_dns_a_record` - Custom private DNS A records
- `azurerm_dns_a_record` - Custom public DNS A records
- `azurerm_dns_cname_record` - Custom public DNS CNAME records

## Usage

```hcl
module "dns" {
  source = "./modules/dns"

  resource_group_name = "rg-aks-dev"
  virtual_network_id  = module.networking.vnet_id

  # Private DNS Configuration
  enable_private_dns      = true
  private_dns_zone_name   = "privatelink.eastus.azmk8s.io"
  enable_auto_registration = false

  # Public DNS Configuration
  enable_public_dns     = true
  public_dns_zone_name  = "example.com"

  # Service-specific Private DNS
  enable_acr_private_dns      = true
  enable_keyvault_private_dns = true
  enable_storage_private_dns  = true

  # AKS API Server (for private clusters)
  aks_api_server_ip          = "10.0.1.100"
  aks_api_server_record_name = "api"

  # Custom DNS Records
  custom_private_dns_records = {
    app1 = {
      name    = "app1"
      records = ["10.0.1.10"]
      ttl     = 300
      tags    = { Environment = "dev" }
    }
  }

  custom_public_dns_records = {
    www = {
      name    = "www"
      records = ["1.2.3.4"]
      ttl     = 300
      tags    = { Environment = "dev" }
    }
  }

  custom_public_cname_records = {
    api = {
      name   = "api"
      record = "api.example.com"
      ttl    = 300
      tags   = { Environment = "dev" }
    }
  }

  tags = {
    Environment = "dev"
    Project     = "aks-infrastructure"
  }
}
```

## Private DNS Zones

The module creates private DNS zones for the following services:

### AKS Private DNS Zone
- **Zone Name**: Configurable (default: `privatelink.eastus.azmk8s.io`)
- **Purpose**: DNS resolution for private AKS clusters
- **Records**: API server A record (optional)

### Azure Container Registry
- **Zone Name**: `privatelink.azurecr.io`
- **Purpose**: DNS resolution for ACR private endpoints
- **Enabled**: When `enable_acr_private_dns = true`

### Azure Key Vault
- **Zone Name**: `privatelink.vaultcore.azure.net`
- **Purpose**: DNS resolution for Key Vault private endpoints
- **Enabled**: When `enable_keyvault_private_dns = true`

### Azure Storage Account
- **Zone Name**: `privatelink.blob.core.windows.net`
- **Purpose**: DNS resolution for Storage Account private endpoints
- **Enabled**: When `enable_storage_private_dns = true`

## Public DNS Zone

When enabled, creates a public DNS zone for external DNS resolution:

- Configurable zone name
- Support for custom A and CNAME records
- Returns name servers for domain delegation

## Custom DNS Records

### Private DNS Records
Add custom A records to the private DNS zone:

```hcl
custom_private_dns_records = {
  database = {
    name    = "db"
    records = ["10.0.2.100"]
    ttl     = 300
    tags    = { Service = "database" }
  }
  cache = {
    name    = "redis"
    records = ["10.0.2.101"]
    ttl     = 300
    tags    = { Service = "cache" }
  }
}
```

### Public DNS Records
Add custom A records to the public DNS zone:

```hcl
custom_public_dns_records = {
  web = {
    name    = "www"
    records = ["203.0.113.1", "203.0.113.2"]
    ttl     = 300
    tags    = { Service = "web" }
  }
}
```

### Public CNAME Records
Add custom CNAME records to the public DNS zone:

```hcl
custom_public_cname_records = {
  api = {
    name   = "api"
    record = "api-gateway.example.com"
    ttl    = 300
    tags   = { Service = "api" }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| resource_group_name | Name of the resource group | `string` | n/a | yes |
| virtual_network_id | ID of the virtual network to link DNS zones to | `string` | n/a | yes |
| enable_private_dns | Enable private DNS zone for AKS | `bool` | `true` | no |
| enable_public_dns | Enable public DNS zone | `bool` | `false` | no |
| enable_acr_private_dns | Enable private DNS zone for Azure Container Registry | `bool` | `false` | no |
| enable_keyvault_private_dns | Enable private DNS zone for Key Vault | `bool` | `false` | no |
| enable_storage_private_dns | Enable private DNS zone for Storage Account | `bool` | `false` | no |
| private_dns_zone_name | Name of the private DNS zone for AKS | `string` | `"privatelink.eastus.azmk8s.io"` | no |
| public_dns_zone_name | Name of the public DNS zone | `string` | `null` | no |
| enable_auto_registration | Enable auto registration for private DNS zone | `bool` | `false` | no |
| aks_api_server_ip | IP address of the AKS API server (for private clusters) | `string` | `null` | no |
| aks_api_server_record_name | DNS record name for AKS API server | `string` | `"api"` | no |
| dns_record_ttl | TTL for DNS records | `number` | `300` | no |
| custom_private_dns_records | Map of custom private DNS A records | `map(object)` | `{}` | no |
| custom_public_dns_records | Map of custom public DNS A records | `map(object)` | `{}` | no |
| custom_public_cname_records | Map of custom public DNS CNAME records | `map(object)` | `{}` | no |
| tags | A map of tags to assign to the resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| private_dns_zone_id | ID of the private DNS zone |
| private_dns_zone_name | Name of the private DNS zone |
| public_dns_zone_id | ID of the public DNS zone |
| public_dns_zone_name | Name of the public DNS zone |
| public_dns_zone_name_servers | Name servers for the public DNS zone |
| acr_private_dns_zone_id | ID of the ACR private DNS zone |
| keyvault_private_dns_zone_id | ID of the Key Vault private DNS zone |
| storage_private_dns_zone_id | ID of the Storage private DNS zone |
| private_dns_zone_virtual_network_link_id | ID of the private DNS zone virtual network link |
| custom_private_dns_records | Map of custom private DNS A records |
| custom_public_dns_records | Map of custom public DNS A records |
| custom_public_cname_records | Map of custom public DNS CNAME records |

## Examples

### Basic Private DNS Setup
```hcl
module "dns" {
  source = "./modules/dns"

  resource_group_name   = "rg-aks-dev"
  virtual_network_id    = module.networking.vnet_id
  enable_private_dns    = true
  private_dns_zone_name = "privatelink.eastus.azmk8s.io"

  tags = {
    Environment = "dev"
  }
}
```

### Complete DNS Setup with All Services
```hcl
module "dns" {
  source = "./modules/dns"

  resource_group_name = "rg-aks-prod"
  virtual_network_id  = module.networking.vnet_id

  # Enable all DNS zones
  enable_private_dns          = true
  enable_public_dns           = true
  enable_acr_private_dns      = true
  enable_keyvault_private_dns = true
  enable_storage_private_dns  = true

  # DNS zone names
  private_dns_zone_name = "privatelink.eastus.azmk8s.io"
  public_dns_zone_name  = "mycompany.com"

  # AKS private cluster
  aks_api_server_ip = "10.0.1.100"

  tags = {
    Environment = "prod"
    Project     = "aks-infrastructure"
  }
}
```
