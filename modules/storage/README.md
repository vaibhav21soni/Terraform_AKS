# Storage Module

This module creates and manages Azure Storage Accounts and Containers for AKS-related storage needs including logs, backups, and application data.

## 📋 Purpose

The Storage module provides scalable and secure storage solutions with:
- Multiple storage accounts for different purposes
- Organized container structure for data segregation
- Network access controls and security features
- Integration with AKS for persistent storage needs
- Backup and disaster recovery capabilities

## 🏗️ Resources Created

- **azurerm_storage_account**: Storage accounts with specified configurations
- **azurerm_storage_container**: Blob containers for organized data storage
- **random_string**: Unique suffixes for storage account naming

## 📥 Input Variables

| Variable | Type | Description | Default | Required |
|----------|------|-------------|---------|----------|
| `environment` | string | Environment name | - | ✅ |
| `resource_group_name` | string | Name of the resource group | - | ✅ |
| `location` | string | Azure region | - | ✅ |
| `storage_accounts` | map(object) | Map of storage accounts to create | - | ✅ |
| `tags` | map(string) | Tags to assign to resources | `{}` | ❌ |

### Storage Accounts Object Structure
```hcl
storage_accounts = {
  main = {
    account_tier             = "Standard"
    account_replication_type = "LRS"
    account_kind            = "StorageV2"
    access_tier             = "Hot"
    enable_https_traffic_only = true
    min_tls_version         = "TLS1_2"
    containers = [
      {
        name                  = "logs"
        container_access_type = "private"
      },
      {
        name                  = "backups"
        container_access_type = "private"
      }
    ]
    network_rules = {
      default_action             = "Allow"
      bypass                     = ["AzureServices"]
      ip_rules                   = []
      virtual_network_subnet_ids = []
    }
    tags = {
      Purpose = "main-storage"
    }
  }
}
```

## 📤 Outputs

| Output | Type | Description |
|--------|------|-------------|
| `storage_accounts` | map(object) | Map of storage account details including IDs, names, keys, and endpoints |
| `storage_containers` | map(object) | Map of storage container details including IDs and names |

## 🚀 Usage Examples

### Basic Storage Configuration
```hcl
module "storage" {
  source = "./modules/storage"
  
  environment         = "dev"
  resource_group_name = "rg-aks-dev"
  location           = "East US"
  
  storage_accounts = {
    main = {
      account_tier             = "Standard"
      account_replication_type = "LRS"
      account_kind            = "StorageV2"
      access_tier             = "Hot"
      enable_https_traffic_only = true
      min_tls_version         = "TLS1_2"
      containers = [
        {
          name                  = "logs"
          container_access_type = "private"
        },
        {
          name                  = "backups"
          container_access_type = "private"
        }
      ]
      network_rules = {
        default_action             = "Allow"
        bypass                     = ["AzureServices"]
        ip_rules                   = []
        virtual_network_subnet_ids = []
      }
      tags = {
        Purpose = "development-storage"
      }
    }
  }
  
  tags = {
    Environment = "development"
    Project     = "aks-demo"
  }
}
```

### Production Storage with Multiple Accounts
```hcl
module "storage" {
  source = "./modules/storage"
  
  environment         = "prod"
  resource_group_name = "rg-aks-prod"
  location           = "East US"
  
  storage_accounts = {
    # Main storage for application data
    main = {
      account_tier             = "Standard"
      account_replication_type = "RAGRS"
      account_kind            = "StorageV2"
      access_tier             = "Hot"
      enable_https_traffic_only = true
      min_tls_version         = "TLS1_2"
      containers = [
        {
          name                  = "logs"
          container_access_type = "private"
        },
        {
          name                  = "artifacts"
          container_access_type = "private"
        },
        {
          name                  = "monitoring"
          container_access_type = "private"
        }
      ]
      network_rules = {
        default_action             = "Deny"
        bypass                     = ["AzureServices"]
        ip_rules                   = ["203.0.113.0/24"]
        virtual_network_subnet_ids = [module.networking.aks_subnet_id]
      }
      tags = {
        Purpose = "production-storage"
        Tier    = "hot"
      }
    }
    
    # Backup storage with cool tier
    backup = {
      account_tier             = "Standard"
      account_replication_type = "RAGRS"
      account_kind            = "StorageV2"
      access_tier             = "Cool"
      enable_https_traffic_only = true
      min_tls_version         = "TLS1_2"
      containers = [
        {
          name                  = "database-backups"
          container_access_type = "private"
        },
        {
          name                  = "application-backups"
          container_access_type = "private"
        }
      ]
      network_rules = {
        default_action             = "Deny"
        bypass                     = ["AzureServices"]
        ip_rules                   = []
        virtual_network_subnet_ids = []
      }
      tags = {
        Purpose = "backup-storage"
        Tier    = "cool"
      }
    }
    
    # Archive storage for long-term retention
    archive = {
      account_tier             = "Standard"
      account_replication_type = "LRS"
      account_kind            = "StorageV2"
      access_tier             = "Archive"
      enable_https_traffic_only = true
      min_tls_version         = "TLS1_2"
      containers = [
        {
          name                  = "long-term-backups"
          container_access_type = "private"
        },
        {
          name                  = "compliance-data"
          container_access_type = "private"
        }
      ]
      network_rules = {
        default_action             = "Deny"
        bypass                     = ["AzureServices"]
        ip_rules                   = []
        virtual_network_subnet_ids = []
      }
      tags = {
        Purpose = "archive-storage"
        Tier    = "archive"
      }
    }
  }
  
  tags = {
    Environment = "production"
    Project     = "aks-platform"
    Criticality = "high"
  }
}
```

### Staging with Network Restrictions
```hcl
module "storage" {
  source = "./modules/storage"
  
  environment         = "staging"
  resource_group_name = "rg-aks-staging"
  location           = "East US"
  
  storage_accounts = {
    main = {
      account_tier             = "Standard"
      account_replication_type = "GRS"
      account_kind            = "StorageV2"
      access_tier             = "Hot"
      enable_https_traffic_only = true
      min_tls_version         = "TLS1_2"
      containers = [
        {
          name                  = "logs"
          container_access_type = "private"
        },
        {
          name                  = "backups"
          container_access_type = "private"
        },
        {
          name                  = "artifacts"
          container_access_type = "private"
        }
      ]
      network_rules = {
        default_action             = "Allow"
        bypass                     = ["AzureServices"]
        ip_rules                   = []
        virtual_network_subnet_ids = []
      }
      tags = {
        Purpose = "staging-storage"
      }
    }
  }
  
  tags = {
    Environment = "staging"
    Project     = "aks-demo"
  }
}
```

## 🎯 Storage Account Types and Use Cases

### Main Storage Account
**Purpose**: Primary application data and logs
- **Tier**: Hot (frequently accessed data)
- **Replication**: LRS/GRS based on requirements
- **Containers**: logs, artifacts, monitoring data

### Backup Storage Account
**Purpose**: Backup and disaster recovery
- **Tier**: Cool (infrequently accessed)
- **Replication**: RAGRS for geo-redundancy
- **Containers**: database-backups, application-backups

### Archive Storage Account
**Purpose**: Long-term retention and compliance
- **Tier**: Archive (rarely accessed)
- **Replication**: LRS (cost-optimized)
- **Containers**: long-term-backups, compliance-data

## 🔒 Security Features

### Network Access Controls
```hcl
network_rules = {
  default_action             = "Deny"
  bypass                     = ["AzureServices"]
  ip_rules                   = ["203.0.113.0/24"]  # Office IP range
  virtual_network_subnet_ids = [module.networking.aks_subnet_id]
}
```

### Encryption and Security
- **HTTPS Only**: `enable_https_traffic_only = true`
- **TLS Version**: `min_tls_version = "TLS1_2"`
- **Blob Versioning**: Automatically enabled
- **Soft Delete**: 7-day retention for accidental deletions

### Container Access Types
- **private**: No anonymous access (recommended)
- **blob**: Anonymous read access to blobs only
- **container**: Anonymous read access to containers and blobs

## 📊 Storage Tiers and Performance

### Hot Tier
- **Use Case**: Frequently accessed data
- **Cost**: Higher storage cost, lower access cost
- **Examples**: Application logs, active datasets

### Cool Tier
- **Use Case**: Infrequently accessed data (30+ days)
- **Cost**: Lower storage cost, higher access cost
- **Examples**: Backups, archived logs

### Archive Tier
- **Use Case**: Rarely accessed data (180+ days)
- **Cost**: Lowest storage cost, highest access cost
- **Examples**: Compliance data, long-term backups

## 🔗 AKS Integration

### Persistent Volumes
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: azure-blob-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteMany
  csi:
    driver: blob.csi.azure.com
    volumeHandle: unique-volume-id
    volumeAttributes:
      containerName: logs
      storageAccount: ${module.storage.storage_accounts.main.name}
```

### Storage Classes
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: azure-blob-storage
provisioner: blob.csi.azure.com
parameters:
  storageAccount: ${module.storage.storage_accounts.main.name}
  containerName: artifacts
  protocol: fuse
```

### Application Configuration
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: storage-secret
type: Opaque
data:
  connection-string: ${base64encode(module.storage.storage_accounts.main.primary_connection_string)}
```

## 🔍 Storage Management

### Blob Operations
```bash
# Upload file to container
az storage blob upload \
  --account-name ${storage_account_name} \
  --container-name logs \
  --name app.log \
  --file ./app.log

# List blobs in container
az storage blob list \
  --account-name ${storage_account_name} \
  --container-name logs

# Download blob
az storage blob download \
  --account-name ${storage_account_name} \
  --container-name backups \
  --name backup.tar.gz \
  --file ./backup.tar.gz
```

### Container Management
```bash
# Create container
az storage container create \
  --account-name ${storage_account_name} \
  --name new-container

# Set container permissions
az storage container set-permission \
  --account-name ${storage_account_name} \
  --name logs \
  --public-access off
```

### Access Key Management
```bash
# Rotate access keys
az storage account keys renew \
  --account-name ${storage_account_name} \
  --key key1

# List access keys
az storage account keys list \
  --account-name ${storage_account_name}
```

## 📈 Monitoring and Metrics

### Storage Metrics
- **Capacity**: Total storage used
- **Transactions**: Number of requests
- **Availability**: Service uptime
- **Latency**: Request response times

### Diagnostic Logging
```bash
# Enable diagnostic settings
az monitor diagnostic-settings create \
  --resource ${storage_account_id} \
  --name "storage-diagnostics" \
  --workspace ${log_analytics_workspace_id} \
  --logs '[{"category":"StorageRead","enabled":true},{"category":"StorageWrite","enabled":true},{"category":"StorageDelete","enabled":true}]' \
  --metrics '[{"category":"Transaction","enabled":true}]'
```

### Cost Monitoring
```bash
# Check storage costs
az consumption usage list \
  --start-date 2024-01-01 \
  --end-date 2024-01-31 \
  --query "[?contains(instanceName, '${storage_account_name}')]"
```

## 💰 Cost Optimization

### Storage Tier Management
```bash
# Move blobs to cool tier
az storage blob set-tier \
  --account-name ${storage_account_name} \
  --container-name logs \
  --name old-log.txt \
  --tier Cool

# Lifecycle management policy
az storage account management-policy create \
  --account-name ${storage_account_name} \
  --policy @lifecycle-policy.json
```

### Lifecycle Policy Example
```json
{
  "rules": [
    {
      "name": "move-to-cool",
      "enabled": true,
      "type": "Lifecycle",
      "definition": {
        "filters": {
          "blobTypes": ["blockBlob"],
          "prefixMatch": ["logs/"]
        },
        "actions": {
          "baseBlob": {
            "tierToCool": {
              "daysAfterModificationGreaterThan": 30
            },
            "tierToArchive": {
              "daysAfterModificationGreaterThan": 90
            },
            "delete": {
              "daysAfterModificationGreaterThan": 365
            }
          }
        }
      }
    }
  ]
}
```

## 🔄 Backup and Disaster Recovery

### Backup Strategies
- **Cross-region replication**: RAGRS for geo-redundancy
- **Point-in-time restore**: Available for certain scenarios
- **Blob versioning**: Automatic version management
- **Soft delete**: Protection against accidental deletion

### Disaster Recovery
```bash
# Check replication status
az storage account show \
  --name ${storage_account_name} \
  --query "statusOfPrimary"

# Initiate failover (if needed)
az storage account failover \
  --name ${storage_account_name}
```

## 🚨 Troubleshooting

### Common Issues

#### Access Denied Errors
```bash
# Check network rules
az storage account network-rule list \
  --account-name ${storage_account_name}

# Test connectivity
az storage blob exists \
  --account-name ${storage_account_name} \
  --container-name logs \
  --name test.txt
```

#### Performance Issues
```bash
# Check storage metrics
az monitor metrics list \
  --resource ${storage_account_id} \
  --metric "Transactions"

# Analyze request patterns
az storage logging show \
  --account-name ${storage_account_name}
```

#### Capacity Issues
```bash
# Check storage usage
az storage account show-usage \
  --location "East US"

# List large blobs
az storage blob list \
  --account-name ${storage_account_name} \
  --container-name logs \
  --query "[?properties.contentLength > \`1073741824\`]"  # > 1GB
```

## 🔄 Maintenance Tasks

### Regular Maintenance
- Monitor storage usage and costs
- Review and update lifecycle policies
- Rotate access keys regularly
- Clean up unused containers and blobs

### Security Maintenance
- Review network access rules
- Audit access logs
- Update TLS and encryption settings
- Monitor for unauthorized access

### Performance Optimization
- Analyze access patterns
- Optimize blob organization
- Review replication settings
- Monitor transaction costs

## 🤝 Contributing

When modifying this module:
1. Test with different storage configurations
2. Validate network rule settings
3. Test container access scenarios
4. Update documentation for new features
5. Consider cost implications

## 📚 References

- [Azure Storage Documentation](https://docs.microsoft.com/en-us/azure/storage/)
- [Blob Storage Best Practices](https://docs.microsoft.com/en-us/azure/storage/blobs/storage-performance-checklist)
- [Storage Security Guide](https://docs.microsoft.com/en-us/azure/storage/common/storage-security-guide)
- [AKS Storage Options](https://docs.microsoft.com/en-us/azure/aks/concepts-storage)
