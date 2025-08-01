# Container Registry Module

This module creates and manages Azure Container Registry (ACR) for storing and managing container images used by AKS clusters.

## 📋 Purpose

The Container Registry module provides secure container image storage with:
- Private container registry for each environment
- Geo-replication for high availability
- Network access controls and security policies
- Integration with AKS for seamless image pulling
- Vulnerability scanning and compliance features

## 🏗️ Resources Created

- **azurerm_container_registry**: Azure Container Registry with specified configuration
- **Dynamic geo-replication**: Additional registry replicas in specified regions
- **Network rules**: IP and VNet-based access controls
- **Security policies**: Quarantine, retention, and trust policies

## 📥 Input Variables

| Variable | Type | Description | Default | Required |
|----------|------|-------------|---------|----------|
| `environment` | string | Environment name | - | ✅ |
| `resource_group_name` | string | Name of the resource group | - | ✅ |
| `location` | string | Azure region | - | ✅ |
| `acr_name` | string | Name of the Azure Container Registry | - | ✅ |
| `acr_sku` | string | SKU for the Azure Container Registry | `"Standard"` | ❌ |
| `admin_enabled` | bool | Enable admin user for ACR | `false` | ❌ |
| `georeplication_locations` | list(object) | List of geo-replication locations | `[]` | ❌ |
| `network_rule_set` | object | Network rule set configuration | `null` | ❌ |
| `public_network_access_enabled` | bool | Enable public network access | `true` | ❌ |
| `quarantine_policy_enabled` | bool | Enable quarantine policy | `false` | ❌ |
| `retention_policy_enabled` | bool | Enable retention policy | `false` | ❌ |
| `retention_policy_days` | number | Number of days to retain images | `7` | ❌ |
| `trust_policy_enabled` | bool | Enable trust policy | `false` | ❌ |
| `tags` | map(string) | Tags to assign to resources | `{}` | ❌ |

### Geo-replication Locations Object Structure
```hcl
georeplication_locations = [
  {
    location                = "West US"
    zone_redundancy_enabled = true
    tags = {
      Purpose = "geo-replication"
    }
  }
]
```

### Network Rule Set Object Structure
```hcl
network_rule_set = {
  default_action = "Deny"
  ip_rules = [
    {
      action   = "Allow"
      ip_range = "203.0.113.0/24"
    }
  ]
  virtual_networks = [
    {
      action    = "Allow"
      subnet_id = "/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.Network/virtualNetworks/xxx/subnets/xxx"
    }
  ]
}
```

## 📤 Outputs

| Output | Type | Description |
|--------|------|-------------|
| `acr_id` | string | ID of the Azure Container Registry |
| `acr_name` | string | Name of the Azure Container Registry |
| `login_server` | string | Login server URL for the registry |
| `admin_username` | string | Admin username (if admin enabled) |
| `admin_password` | string | Admin password (if admin enabled) |

## 🚀 Usage Examples

### Basic Container Registry
```hcl
module "container_registry" {
  source = "./modules/container-registry"
  
  environment         = "dev"
  resource_group_name = "rg-aks-dev"
  location           = "East US"
  acr_name           = "acraksdev"
  acr_sku            = "Basic"
  admin_enabled      = true
  
  tags = {
    Environment = "development"
    Project     = "aks-demo"
  }
}
```

### Production Registry with Geo-replication
```hcl
module "container_registry" {
  source = "./modules/container-registry"
  
  environment         = "prod"
  resource_group_name = "rg-aks-prod"
  location           = "East US"
  acr_name           = "acraksproduction"
  acr_sku            = "Premium"
  admin_enabled      = false
  
  # Geo-replication for high availability
  georeplication_locations = [
    {
      location                = "West US"
      zone_redundancy_enabled = true
      tags = {
        Purpose = "disaster-recovery"
      }
    },
    {
      location                = "West Europe"
      zone_redundancy_enabled = true
      tags = {
        Purpose = "global-distribution"
      }
    }
  ]
  
  # Security policies
  public_network_access_enabled = false
  quarantine_policy_enabled     = true
  retention_policy_enabled      = true
  retention_policy_days         = 90
  trust_policy_enabled          = true
  
  # Network access controls
  network_rule_set = {
    default_action = "Deny"
    ip_rules = [
      {
        action   = "Allow"
        ip_range = "203.0.113.0/24"  # Office IP range
      }
    ]
    virtual_networks = [
      {
        action    = "Allow"
        subnet_id = module.networking.aks_subnet_id
      }
    ]
  }
  
  tags = {
    Environment = "production"
    Project     = "aks-platform"
    Criticality = "high"
  }
}
```

### Staging Registry with Security Features
```hcl
module "container_registry" {
  source = "./modules/container-registry"
  
  environment         = "staging"
  resource_group_name = "rg-aks-staging"
  location           = "East US"
  acr_name           = "acraksStaging"
  acr_sku            = "Standard"
  admin_enabled      = false
  
  # Enable security features
  public_network_access_enabled = true
  quarantine_policy_enabled     = true
  retention_policy_enabled      = true
  retention_policy_days         = 30
  trust_policy_enabled          = false
  
  # Allow access from specific networks
  network_rule_set = {
    default_action = "Allow"
    ip_rules       = []
    virtual_networks = []
  }
  
  tags = {
    Environment = "staging"
    Project     = "aks-demo"
  }
}
```

## 🎯 SKU Comparison

### Basic SKU
- **Use Case**: Development and testing
- **Features**: Basic registry functionality
- **Storage**: 10 GB included
- **Throughput**: 10 MiB/s
- **Geo-replication**: Not supported
- **Webhooks**: 2 webhooks

### Standard SKU
- **Use Case**: Production workloads
- **Features**: Enhanced performance and storage
- **Storage**: 100 GB included
- **Throughput**: 60 MiB/s
- **Geo-replication**: Not supported
- **Webhooks**: 10 webhooks

### Premium SKU
- **Use Case**: High-scale production
- **Features**: All advanced features
- **Storage**: 500 GB included
- **Throughput**: 200 MiB/s
- **Geo-replication**: Supported
- **Webhooks**: 500 webhooks
- **Additional**: Content trust, private link, VNet integration

## 🔒 Security Features

### Network Access Controls
```hcl
# Restrict access to specific IP ranges and VNets
network_rule_set = {
  default_action = "Deny"
  ip_rules = [
    {
      action   = "Allow"
      ip_range = "203.0.113.0/24"  # Corporate network
    }
  ]
  virtual_networks = [
    {
      action    = "Allow"
      subnet_id = module.networking.aks_subnet_id
    }
  ]
}
```

### Content Trust (Premium only)
```hcl
trust_policy_enabled = true
```
**Benefits**:
- Digital signature verification
- Image integrity assurance
- Publisher authentication
- Supply chain security

### Quarantine Policy
```hcl
quarantine_policy_enabled = true
```
**Benefits**:
- Automatic vulnerability scanning
- Quarantine vulnerable images
- Prevent deployment of unsafe images
- Compliance with security policies

### Retention Policy
```hcl
retention_policy_enabled = true
retention_policy_days    = 90
```
**Benefits**:
- Automatic cleanup of old images
- Cost optimization
- Compliance with data retention policies
- Storage management

## 🌍 Geo-replication Strategy

### Multi-region Setup
```hcl
georeplication_locations = [
  {
    location                = "West US"
    zone_redundancy_enabled = true
    tags = {
      Purpose = "disaster-recovery"
      Region  = "west-us"
    }
  },
  {
    location                = "West Europe"
    zone_redundancy_enabled = true
    tags = {
      Purpose = "global-distribution"
      Region  = "west-europe"
    }
  }
]
```

### Benefits of Geo-replication
- **High Availability**: Registry available in multiple regions
- **Disaster Recovery**: Automatic failover capabilities
- **Performance**: Reduced latency for global deployments
- **Compliance**: Data residency requirements

## 🔗 AKS Integration

### Automatic Integration
The AKS module automatically configures ACR integration:
```hcl
# In AKS module
resource "azurerm_role_assignment" "aks_acr" {
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope               = var.acr_id
}
```

### Manual Integration
```bash
# Attach ACR to existing AKS cluster
az aks update -n aks-cluster -g rg-aks --attach-acr acrname

# Or grant AcrPull role manually
az role assignment create \
  --assignee <kubelet-identity-object-id> \
  --role AcrPull \
  --scope /subscriptions/<subscription-id>/resourceGroups/<rg-name>/providers/Microsoft.ContainerRegistry/registries/<acr-name>
```

## 🔍 Container Image Management

### Building and Pushing Images
```bash
# Login to ACR
az acr login --name acraksproduction

# Build and push image
docker build -t acraksproduction.azurecr.io/myapp:v1.0 .
docker push acraksproduction.azurecr.io/myapp:v1.0

# Build with ACR Tasks
az acr build --registry acraksproduction --image myapp:v1.0 .
```

### Image Scanning
```bash
# Scan image for vulnerabilities (Premium SKU)
az acr task run --registry acraksproduction --name scan-task

# View scan results
az acr repository show-manifests --name acraksproduction --repository myapp
```

### Repository Management
```bash
# List repositories
az acr repository list --name acraksproduction

# List tags
az acr repository show-tags --name acraksproduction --repository myapp

# Delete old images
az acr repository delete --name acraksproduction --image myapp:old-tag
```

## 📊 Monitoring and Logging

### Registry Metrics
- **Storage usage**: Monitor registry storage consumption
- **Pull/Push operations**: Track image operations
- **Webhook deliveries**: Monitor webhook success rates
- **Geo-replication sync**: Track replication status

### Diagnostic Settings
```bash
# Enable diagnostic logs
az monitor diagnostic-settings create \
  --resource /subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.ContainerRegistry/registries/<acr-name> \
  --name "acr-diagnostics" \
  --workspace /subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.OperationalInsights/workspaces/<workspace-name> \
  --logs '[{"category":"ContainerRegistryRepositoryEvents","enabled":true},{"category":"ContainerRegistryLoginEvents","enabled":true}]' \
  --metrics '[{"category":"AllMetrics","enabled":true}]'
```

## 💰 Cost Optimization

### Storage Management
- Enable retention policies to automatically delete old images
- Use multi-stage builds to reduce image sizes
- Regularly clean up unused repositories and tags
- Monitor storage usage and optimize image layers

### Geo-replication Costs
- Geo-replication incurs additional storage and bandwidth costs
- Consider replication only to necessary regions
- Monitor cross-region data transfer costs
- Use zone redundancy judiciously

### SKU Selection
- Start with Basic/Standard for development
- Upgrade to Premium only when advanced features are needed
- Consider workload requirements and scale

## 🔄 Maintenance Tasks

### Regular Maintenance
- Review and update retention policies
- Monitor storage usage and costs
- Update network access rules as needed
- Review and rotate admin credentials (if used)

### Security Maintenance
- Regularly scan images for vulnerabilities
- Update trust policies and signatures
- Review access logs and audit trails
- Update network security rules

### Performance Optimization
- Monitor pull/push performance
- Optimize image sizes and layers
- Review geo-replication performance
- Consider caching strategies

## 🚨 Troubleshooting

### Common Issues

#### Authentication Problems
```bash
# Check AKS-ACR integration
az aks check-acr --name aks-cluster --resource-group rg-aks --acr acrname

# Verify role assignments
az role assignment list --scope /subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.ContainerRegistry/registries/<acr-name>
```

#### Network Access Issues
```bash
# Test network connectivity
az acr check-health --name acrname

# Check network rules
az acr network-rule list --name acrname
```

#### Image Pull Issues
```bash
# Check image exists
az acr repository show --name acrname --repository myapp

# Test image pull
docker pull acrname.azurecr.io/myapp:latest
```

## 🤝 Contributing

When modifying this module:
1. Test with different SKU configurations
2. Validate network rule configurations
3. Test geo-replication scenarios
4. Update documentation for new features
5. Consider security implications

## 📚 References

- [Azure Container Registry Documentation](https://docs.microsoft.com/en-us/azure/container-registry/)
- [ACR Best Practices](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-best-practices)
- [AKS and ACR Integration](https://docs.microsoft.com/en-us/azure/aks/cluster-container-registry-integration)
- [ACR Security](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-security)
