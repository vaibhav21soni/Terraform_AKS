# Key Vault Module

This module creates and manages Azure Key Vault with comprehensive support for secrets, keys, certificates, access policies, RBAC, private endpoints, and monitoring.

## Features

- **Key Vault Management**: Create and configure Azure Key Vault with various settings
- **Secrets Management**: Store and manage secrets with expiration dates
- **Keys Management**: Create and manage cryptographic keys with rotation policies
- **Certificates Management**: Create and manage certificates with custom policies
- **Access Control**: Support for both Access Policies and RBAC authorization
- **Private Endpoints**: Secure access through private endpoints
- **Network Security**: Network ACLs for restricting access
- **Monitoring**: Diagnostic settings for logging and metrics
- **Compliance**: Purge protection and soft delete for compliance requirements

## Resources Created

- `azurerm_key_vault` - The Key Vault instance
- `azurerm_key_vault_access_policy` - Access policies (when RBAC is disabled)
- `azurerm_role_assignment` - RBAC role assignments (when RBAC is enabled)
- `azurerm_key_vault_secret` - Secrets stored in the Key Vault
- `azurerm_key_vault_key` - Cryptographic keys
- `azurerm_key_vault_certificate` - Certificates with custom policies
- `azurerm_private_endpoint` - Private endpoint for secure access
- `azurerm_monitor_diagnostic_setting` - Diagnostic settings for monitoring

## Usage

### Basic Key Vault
```hcl
module "key_vault" {
  source = "./modules/key-vault"

  environment         = "dev"
  resource_group_name = "rg-aks-dev"
  location           = "East US"
  key_vault_name     = "kv-aks"

  # Basic configuration
  sku_name                     = "standard"
  purge_protection_enabled     = false
  soft_delete_retention_days   = 7
  public_network_access_enabled = true

  tags = {
    Environment = "dev"
    Project     = "aks-infrastructure"
  }
}
```

### Key Vault with Secrets and Keys
```hcl
module "key_vault" {
  source = "./modules/key-vault"

  environment         = "prod"
  resource_group_name = "rg-aks-prod"
  location           = "East US"
  key_vault_name     = "kv-aks"

  # Production configuration
  sku_name                     = "premium"
  purge_protection_enabled     = true
  soft_delete_retention_days   = 90
  public_network_access_enabled = false

  # Secrets
  secrets = {
    database-password = {
      value           = "super-secret-password"
      content_type    = "password"
      expiration_date = "2025-12-31T23:59:59Z"
      tags           = { Service = "database" }
    }
    api-key = {
      value           = "api-key-value"
      content_type    = "api-key"
      expiration_date = null
      tags           = { Service = "api" }
    }
  }

  # Keys
  keys = {
    encryption-key = {
      key_type        = "RSA"
      key_size        = 2048
      curve           = null
      key_opts        = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]
      expiration_date = null
      rotation_policy = {
        time_after_creation  = "P90D"
        time_before_expiry   = "P30D"
        expire_after         = "P2Y"
        notify_before_expiry = "P30D"
      }
      tags = { Purpose = "encryption" }
    }
  }

  # Network restrictions
  network_acls = {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    ip_rules                   = ["203.0.113.0/24"]
    virtual_network_subnet_ids = [var.subnet_id]
  }

  tags = {
    Environment = "prod"
    Project     = "aks-infrastructure"
  }
}
```

### Key Vault with RBAC and Private Endpoint
```hcl
module "key_vault" {
  source = "./modules/key-vault"

  environment         = "prod"
  resource_group_name = "rg-aks-prod"
  location           = "East US"
  key_vault_name     = "kv-aks"

  # RBAC configuration
  enable_rbac_authorization = true
  
  rbac_assignments = {
    admin = {
      role_definition_name = "Key Vault Administrator"
      principal_id         = "user-object-id"
    }
    aks_identity = {
      role_definition_name = "Key Vault Secrets User"
      principal_id         = var.aks_identity_principal_id
    }
  }

  # Private endpoint
  enable_private_endpoint     = true
  private_endpoint_subnet_id  = var.private_endpoint_subnet_id
  private_dns_zone_id        = var.keyvault_private_dns_zone_id
  public_network_access_enabled = false

  # Monitoring
  log_analytics_workspace_id = var.log_analytics_workspace_id

  tags = {
    Environment = "prod"
    Project     = "aks-infrastructure"
  }
}
```

### Key Vault with Certificates
```hcl
module "key_vault" {
  source = "./modules/key-vault"

  environment         = "prod"
  resource_group_name = "rg-aks-prod"
  location           = "East US"
  key_vault_name     = "kv-aks"

  certificates = {
    ssl-cert = {
      certificate_policy = {
        issuer_name         = "Self"
        exportable          = true
        key_size            = 2048
        key_type            = "RSA"
        reuse_key           = true
        action_type         = "AutoRenew"
        days_before_expiry  = 30
        lifetime_percentage = 80
        content_type        = "application/x-pkcs12"
        extended_key_usage  = ["1.3.6.1.5.5.7.3.1"]
        key_usage           = ["cRLSign", "dataEncipherment", "digitalSignature", "keyAgreement", "keyCertSign", "keyEncipherment"]
        subject             = "CN=example.com"
        validity_in_months  = 12
        subject_alternative_names = {
          dns_names = ["example.com", "www.example.com"]
          emails    = []
          upns      = []
        }
      }
      tags = { Purpose = "ssl" }
    }
  }

  tags = {
    Environment = "prod"
    Project     = "aks-infrastructure"
  }
}
```

## Access Control

### Access Policies (Traditional)
When `enable_rbac_authorization = false`, use access policies:

```hcl
access_policies = {
  aks_identity = {
    object_id = var.aks_identity_object_id
    key_permissions = ["Get", "List"]
    secret_permissions = ["Get", "List"]
    certificate_permissions = ["Get", "List"]
    storage_permissions = []
  }
  admin_user = {
    object_id = "admin-user-object-id"
    key_permissions = ["Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey"]
    secret_permissions = ["Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"]
    certificate_permissions = ["Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update"]
    storage_permissions = []
  }
}
```

### RBAC Authorization (Recommended)
When `enable_rbac_authorization = true`, use RBAC assignments:

```hcl
rbac_assignments = {
  admin = {
    role_definition_name = "Key Vault Administrator"
    principal_id         = "admin-user-object-id"
  }
  secrets_user = {
    role_definition_name = "Key Vault Secrets User"
    principal_id         = var.aks_identity_principal_id
  }
  crypto_user = {
    role_definition_name = "Key Vault Crypto User"
    principal_id         = var.app_identity_principal_id
  }
}
```

## Security Features

### Network Security
- **Network ACLs**: Restrict access by IP ranges and VNet subnets
- **Private Endpoints**: Secure access through private network connectivity
- **Public Access Control**: Disable public network access when using private endpoints

### Data Protection
- **Soft Delete**: Automatic soft delete with configurable retention period
- **Purge Protection**: Prevent permanent deletion of Key Vault and its contents
- **HSM Support**: Premium SKU provides Hardware Security Module support

### Compliance
- **Audit Logging**: Comprehensive audit logs through diagnostic settings
- **Access Monitoring**: Track all access to secrets, keys, and certificates
- **Retention Policies**: Configurable retention for compliance requirements

## Monitoring and Diagnostics

The module automatically configures diagnostic settings when `log_analytics_workspace_id` is provided:

### Available Log Categories
- `AuditEvent` - Key Vault access audit events
- `AzurePolicyEvaluationDetails` - Azure Policy evaluation details

### Available Metrics
- `AllMetrics` - All Key Vault metrics including request counts, latency, and availability

## Integration with AKS

### CSI Secret Store Driver
Use with AKS CSI Secret Store Driver to mount secrets as volumes:

```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: app-secrets
spec:
  provider: azure
  parameters:
    usePodIdentity: "false"
    useVMManagedIdentity: "true"
    userAssignedIdentityClientID: "client-id"
    keyvaultName: "kv-aks-prod"
    objects: |
      array:
        - |
          objectName: database-password
          objectType: secret
        - |
          objectName: api-key
          objectType: secret
```

### Workload Identity
Configure workload identity for secure access:

```hcl
# In your AKS configuration
enable_workload_identity = true
enable_oidc_issuer       = true

# RBAC assignment for workload identity
rbac_assignments = {
  workload_identity = {
    role_definition_name = "Key Vault Secrets User"
    principal_id         = var.workload_identity_principal_id
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment name | `string` | n/a | yes |
| resource_group_name | Name of the resource group | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| key_vault_name | Name of the Key Vault | `string` | n/a | yes |
| sku_name | The Name of the SKU used for this Key Vault | `string` | `"standard"` | no |
| enabled_for_deployment | Boolean flag to specify whether Azure Virtual Machines are permitted to retrieve certificates | `bool` | `false` | no |
| enabled_for_disk_encryption | Boolean flag to specify whether Azure Disk Encryption is permitted to retrieve secrets | `bool` | `false` | no |
| enabled_for_template_deployment | Boolean flag to specify whether Azure Resource Manager is permitted to retrieve secrets | `bool` | `false` | no |
| enable_rbac_authorization | Boolean flag to specify whether Azure Key Vault uses Role Based Access Control (RBAC) for authorization | `bool` | `false` | no |
| purge_protection_enabled | Is Purge Protection enabled for this Key Vault? | `bool` | `false` | no |
| soft_delete_retention_days | The number of days that items should be retained for once soft-deleted | `number` | `90` | no |
| public_network_access_enabled | Whether public network access is allowed for this Key Vault | `bool` | `true` | no |
| network_acls | Network ACLs for the Key Vault | `object` | `null` | no |
| access_policies | Map of access policies for the Key Vault (used when RBAC is disabled) | `map(object)` | `{}` | no |
| rbac_assignments | Map of RBAC role assignments for the Key Vault (used when RBAC is enabled) | `map(object)` | `{}` | no |
| secrets | Map of secrets to create in the Key Vault | `map(object)` | `{}` | no |
| keys | Map of keys to create in the Key Vault | `map(object)` | `{}` | no |
| certificates | Map of certificates to create in the Key Vault | `map(object)` | `{}` | no |
| enable_private_endpoint | Enable private endpoint for Key Vault | `bool` | `false` | no |
| private_endpoint_subnet_id | Subnet ID for the private endpoint | `string` | `null` | no |
| private_dns_zone_id | Private DNS zone ID for the private endpoint | `string` | `null` | no |
| log_analytics_workspace_id | Log Analytics workspace ID for diagnostic settings | `string` | `null` | no |
| diagnostic_logs | List of diagnostic log categories to enable | `list(string)` | `["AuditEvent", "AzurePolicyEvaluationDetails"]` | no |
| diagnostic_metrics | List of diagnostic metric categories to enable | `list(string)` | `["AllMetrics"]` | no |
| tags | A map of tags to assign to the resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| key_vault_id | ID of the Key Vault |
| key_vault_name | Name of the Key Vault |
| key_vault_uri | URI of the Key Vault |
| key_vault_tenant_id | Tenant ID of the Key Vault |
| secrets | Map of created secrets |
| keys | Map of created keys |
| certificates | Map of created certificates |
| private_endpoint_id | ID of the private endpoint |
| private_endpoint_ip_address | Private IP address of the private endpoint |
| private_endpoint_fqdn | FQDN of the private endpoint |
| access_policies | Map of access policies |
| rbac_assignments | Map of RBAC role assignments |
| diagnostic_setting_id | ID of the diagnostic setting |
