# Identity Module

This module creates and manages Azure User Assigned Identities and Role-Based Access Control (RBAC) assignments for AKS and related services.

## 📋 Purpose

The Identity module provides secure identity management for AKS clusters and associated workloads by:
- Creating User Assigned Managed Identities
- Configuring RBAC role assignments
- Managing service-to-service authentication
- Enabling workload identity scenarios

## 🏗️ Resources Created

- **azurerm_user_assigned_identity**: Primary AKS cluster identity
- **azurerm_user_assigned_identity**: Additional identities for specific workloads
- **azurerm_role_assignment**: Network Contributor role for AKS identity
- **azurerm_role_assignment**: Custom role assignments for additional identities

## 📥 Input Variables

| Variable | Type | Description | Default | Required |
|----------|------|-------------|---------|----------|
| `environment` | string | Environment name | - | ✅ |
| `resource_group_name` | string | Name of the resource group | - | ✅ |
| `location` | string | Azure region | - | ✅ |
| `cluster_name` | string | Name of the AKS cluster | - | ✅ |
| `vnet_id` | string | ID of the virtual network for role assignments | `""` | ❌ |
| `enable_network_contributor_role` | bool | Enable Network Contributor role for AKS identity | `true` | ❌ |
| `identities` | map(object) | Map of additional user assigned identities to create | `{}` | ❌ |
| `tags` | map(string) | A map of tags to assign to the resources | `{}` | ❌ |

### Identities Object Structure
```hcl
identities = {
  workload = {
    tags = {
      Purpose = "workload-identity"
    }
    role_assignments = [
      {
        role_definition_name = "Storage Blob Data Reader"
        scope               = "/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.Storage/storageAccounts/xxx"
      }
    ]
  }
}
```

## 📤 Outputs

| Output | Type | Description |
|--------|------|-------------|
| `aks_identity_id` | string | ID of the AKS user assigned identity |
| `aks_identity_principal_id` | string | Principal ID of the AKS user assigned identity |
| `aks_identity_client_id` | string | Client ID of the AKS user assigned identity |
| `additional_identities` | map(object) | Map of additional user assigned identities with their IDs, principal IDs, and client IDs |

## 🚀 Usage Examples

### Basic AKS Identity
```hcl
module "identity" {
  source = "./modules/identity"
  
  environment                    = "dev"
  resource_group_name           = "rg-aks-dev"
  location                     = "East US"
  cluster_name                 = "aks-dev-cluster"
  vnet_id                      = "/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.Network/virtualNetworks/xxx"
  enable_network_contributor_role = true
  
  tags = {
    Environment = "development"
    Project     = "aks-demo"
  }
}
```

### With Additional Workload Identities
```hcl
module "identity" {
  source = "./modules/identity"
  
  environment         = "prod"
  resource_group_name = "rg-aks-prod"
  location           = "East US"
  cluster_name       = "aks-prod-cluster"
  vnet_id            = module.networking.vnet_id
  
  identities = {
    workload = {
      tags = {
        Purpose = "workload-identity"
        Team    = "platform"
      }
      role_assignments = [
        {
          role_definition_name = "Storage Blob Data Reader"
          scope               = module.storage.storage_accounts["main"].id
        },
        {
          role_definition_name = "Key Vault Secrets User"
          scope               = module.key_vault.key_vault_id
        }
      ]
    }
    
    monitoring = {
      tags = {
        Purpose = "monitoring-identity"
        Team    = "sre"
      }
      role_assignments = [
        {
          role_definition_name = "Monitoring Metrics Publisher"
          scope               = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
        }
      ]
    }
    
    backup = {
      tags = {
        Purpose = "backup-identity"
        Team    = "platform"
      }
      role_assignments = [
        {
          role_definition_name = "Storage Blob Data Contributor"
          scope               = module.storage.storage_accounts["backup"].id
        }
      ]
    }
  }
  
  tags = {
    Environment = "production"
    Project     = "aks-platform"
  }
}
```

### Multi-Environment Usage
```hcl
module "identity" {
  source = "./modules/identity"
  
  for_each = var.environments
  
  environment                    = each.key
  resource_group_name           = module.resource_group[each.key].name
  location                     = module.resource_group[each.key].location
  cluster_name                 = each.value.cluster_name
  vnet_id                      = module.networking[each.key].vnet_id
  enable_network_contributor_role = true
  identities                   = each.value.identities
  
  tags = merge(local.common_tags, each.value.tags, { Environment = each.key })
}
```

## 🔐 Identity Types and Use Cases

### AKS Cluster Identity
**Purpose**: Primary identity for the AKS cluster
**Permissions**: 
- Network Contributor on VNet (for load balancer management)
- AcrPull on Container Registry (configured in AKS module)

**Use Cases**:
- Managing load balancers and public IPs
- Pulling container images from ACR
- Integrating with Azure services

### Workload Identity
**Purpose**: Identity for application workloads running in AKS
**Permissions**: Scoped to specific resources based on application needs

**Use Cases**:
- Accessing Azure Storage from pods
- Reading secrets from Key Vault
- Publishing metrics to Azure Monitor
- Accessing databases with managed identity

### Monitoring Identity
**Purpose**: Identity for monitoring and observability tools
**Permissions**: Metrics publishing and log collection

**Use Cases**:
- Prometheus metrics collection
- Custom monitoring solutions
- Log forwarding to external systems

### Backup Identity
**Purpose**: Identity for backup and disaster recovery operations
**Permissions**: Storage access for backup operations

**Use Cases**:
- Database backups to Azure Storage
- Application data backups
- Cross-region replication

## 🔗 Role Assignment Patterns

### Common Azure Roles
```hcl
# Storage Access
{
  role_definition_name = "Storage Blob Data Reader"
  scope               = azurerm_storage_account.example.id
}

# Key Vault Access
{
  role_definition_name = "Key Vault Secrets User"
  scope               = azurerm_key_vault.example.id
}

# Container Registry Access
{
  role_definition_name = "AcrPull"
  scope               = azurerm_container_registry.example.id
}

# Monitoring Access
{
  role_definition_name = "Monitoring Metrics Publisher"
  scope               = "/subscriptions/${var.subscription_id}"
}

# Network Access
{
  role_definition_name = "Network Contributor"
  scope               = azurerm_virtual_network.example.id
}
```

### Scope Levels
- **Subscription**: `/subscriptions/{subscription-id}`
- **Resource Group**: `/subscriptions/{subscription-id}/resourceGroups/{rg-name}`
- **Resource**: Full resource ID

## 🔗 Dependencies

### Upstream Dependencies
- **resource-group** module: Provides resource group name and location
- **networking** module: Provides VNet ID for role assignments

### Downstream Dependencies
This module's outputs are used by:
- **aks** module: Requires AKS identity ID
- **container-registry** module: May use identity for RBAC
- **storage** module: May use identity for access control
- **key-vault** module: May use identity for access policies

## 🔍 Workload Identity Integration

### Kubernetes Service Account Binding
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: workload-identity-sa
  namespace: default
  annotations:
    azure.workload.identity/client-id: "${module.identity.additional_identities.workload.client_id}"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: workload-app
spec:
  template:
    metadata:
      labels:
        azure.workload.identity/use: "true"
    spec:
      serviceAccountName: workload-identity-sa
      containers:
      - name: app
        image: myapp:latest
```

### Federated Identity Credential
```hcl
resource "azurerm_federated_identity_credential" "workload" {
  name                = "workload-federated-credential"
  resource_group_name = var.resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = module.aks.oidc_issuer_url
  parent_id           = module.identity.additional_identities.workload.id
  subject             = "system:serviceaccount:default:workload-identity-sa"
}
```

## 🔍 Validation and Testing

### Identity Verification
```bash
# Check identity creation
az identity show --resource-group rg-aks-dev --name aks-dev-cluster-dev-identity

# List role assignments
az role assignment list --assignee <principal-id>

# Test identity permissions
az rest --method GET --url "https://management.azure.com/subscriptions/{subscription-id}/resourceGroups/{rg-name}?api-version=2021-04-01" --headers "Authorization=Bearer $(az account get-access-token --query accessToken -o tsv)"
```

### Workload Identity Testing
```bash
# From within a pod with workload identity
curl -H "Metadata: true" "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://management.azure.com/"
```

## 🚨 Security Best Practices

### Principle of Least Privilege
- Grant minimum required permissions
- Use resource-scoped roles when possible
- Regularly review and audit role assignments
- Remove unused identities and assignments

### Identity Lifecycle Management
- Use descriptive names for identities
- Tag identities with purpose and ownership
- Implement identity rotation policies
- Monitor identity usage and access patterns

### Workload Identity Security
- Use namespace isolation
- Implement pod security policies
- Audit service account usage
- Monitor token usage and anomalies

## 📊 Monitoring and Auditing

### Identity Usage Monitoring
```bash
# Check identity sign-in logs
az monitor activity-log list --resource-group rg-aks-dev --caller <principal-id>

# Review role assignment changes
az monitor activity-log list --resource-group rg-aks-dev --category Administrative
```

### Compliance and Auditing
- Enable Azure AD audit logs
- Monitor privileged role assignments
- Track identity creation and deletion
- Review access patterns regularly

## 🔄 Maintenance Tasks

### Regular Reviews
- Audit role assignments quarterly
- Remove unused identities
- Update role assignments based on changing requirements
- Review and update tags

### Identity Rotation
- Plan for identity credential rotation
- Update federated identity credentials
- Test applications after identity changes
- Document identity dependencies

## 🤝 Contributing

When modifying this module:
1. Follow principle of least privilege
2. Document new role assignments
3. Test with different identity scenarios
4. Update examples and documentation
5. Consider security implications

## 📚 References

- [Azure Managed Identity Documentation](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/)
- [AKS Workload Identity](https://docs.microsoft.com/en-us/azure/aks/workload-identity-overview)
- [Azure RBAC Documentation](https://docs.microsoft.com/en-us/azure/role-based-access-control/)
- [Azure Built-in Roles](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles)
