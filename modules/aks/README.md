# AKS Module

This module creates and manages Azure Kubernetes Service (AKS) clusters with support for multiple node pools, advanced features, and comprehensive configuration options.

## 📋 Purpose

The AKS module provides a complete Kubernetes cluster solution with:
- Managed Kubernetes control plane
- Multiple node pool configurations
- Advanced AKS features (Azure Policy, Workload Identity, etc.)
- Integration with Azure services
- Auto-scaling and upgrade management

## 🏗️ Resources Created

- **azurerm_kubernetes_cluster**: Main AKS cluster with control plane
- **azurerm_kubernetes_cluster_node_pool**: Additional node pools for different workload types
- **azurerm_role_assignment**: ACR pull permissions for cluster identity

## 📥 Input Variables

| Variable | Type | Description | Default | Required |
|----------|------|-------------|---------|----------|
| `environment` | string | Environment name | - | ✅ |
| `resource_group_name` | string | Name of the resource group | - | ✅ |
| `location` | string | Azure region | - | ✅ |
| `cluster_name` | string | Name of the AKS cluster | - | ✅ |
| `dns_prefix` | string | DNS prefix for the AKS cluster | - | ✅ |
| `kubernetes_version` | string | Version of Kubernetes to use | `null` | ❌ |
| `sku_tier` | string | The SKU Tier for the cluster | `"Free"` | ❌ |
| `vnet_subnet_id` | string | ID of the subnet for AKS nodes | - | ✅ |
| `identity_ids` | list(string) | List of User Assigned Identity IDs | - | ✅ |
| `network_plugin` | string | Network plugin to use | `"azure"` | ❌ |
| `network_policy` | string | Network policy to use | `"azure"` | ❌ |
| `dns_service_ip` | string | IP address for cluster service discovery | `null` | ❌ |
| `service_cidr` | string | Network range for Kubernetes services | `null` | ❌ |
| `log_analytics_workspace_id` | string | ID of Log Analytics workspace | `null` | ❌ |
| `azure_policy_enabled` | bool | Enable Azure Policy | `false` | ❌ |
| `enable_key_vault_secrets_provider` | bool | Enable Key Vault Secrets Provider | `false` | ❌ |
| `enable_microsoft_defender` | bool | Enable Microsoft Defender | `false` | ❌ |
| `enable_workload_identity` | bool | Enable Workload Identity | `false` | ❌ |
| `enable_oidc_issuer` | bool | Enable OIDC Issuer | `false` | ❌ |
| `acr_id` | string | ID of Azure Container Registry | `null` | ❌ |
| `default_node_pool` | object | Configuration for default node pool | - | ✅ |
| `additional_node_pools` | map(object) | Map of additional node pools | `{}` | ❌ |
| `auto_scaler_profile` | object | Auto scaler profile configuration | `null` | ❌ |
| `tags` | map(string) | Tags to assign to resources | `{}` | ❌ |

### Default Node Pool Object Structure
```hcl
default_node_pool = {
  name                = "default"
  node_count          = 3
  vm_size             = "Standard_D2s_v3"
  enable_auto_scaling = true
  min_count           = 1
  max_count           = 5
  max_pods            = 30
  os_disk_size_gb     = 128
  os_disk_type        = "Managed"
  availability_zones  = ["1", "2", "3"]
  upgrade_settings = {
    max_surge = "10%"
  }
}
```

### Additional Node Pool Object Structure
```hcl
additional_node_pools = {
  system = {
    vm_size             = "Standard_D2s_v3"
    node_count          = 2
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 3
    max_pods            = 30
    os_disk_size_gb     = 128
    os_disk_type        = "Managed"
    os_type             = "Linux"
    node_taints         = ["CriticalAddonsOnly=true:NoSchedule"]
    node_labels = {
      "node-type" = "system"
    }
    availability_zones  = ["1", "2", "3"]
    priority            = "Regular"
    eviction_policy     = ""
    spot_max_price      = -1
    tags = {
      NodePool = "system"
    }
    upgrade_settings = {
      max_surge = "33%"
    }
  }
}
```

## 📤 Outputs

| Output | Type | Description |
|--------|------|-------------|
| `cluster_id` | string | ID of the AKS cluster |
| `cluster_name` | string | Name of the AKS cluster |
| `cluster_fqdn` | string | FQDN of the AKS cluster |
| `cluster_endpoint` | string | Endpoint for the AKS cluster API server |
| `cluster_ca_certificate` | string | Base64 encoded certificate data |
| `kube_config` | string | Raw kubeconfig for the cluster |
| `kubelet_identity` | object | Kubelet identity information |
| `node_resource_group` | string | Auto-generated resource group for nodes |
| `oidc_issuer_url` | string | OIDC Issuer URL |
| `additional_node_pools` | map(string) | Map of additional node pool IDs |

## 🚀 Usage Examples

### Basic AKS Cluster
```hcl
module "aks" {
  source = "./modules/aks"
  
  environment         = "dev"
  resource_group_name = "rg-aks-dev"
  location           = "East US"
  cluster_name       = "aks-dev-cluster"
  dns_prefix         = "aks-dev"
  kubernetes_version = "1.28.3"
  sku_tier          = "Free"
  
  vnet_subnet_id = module.networking.aks_subnet_id
  identity_ids   = [module.identity.aks_identity_id]
  
  default_node_pool = {
    name                = "default"
    node_count          = 1
    vm_size             = "Standard_B2s"
    enable_auto_scaling = false
    min_count           = 1
    max_count           = 1
    max_pods            = 30
    os_disk_size_gb     = 64
    os_disk_type        = "Managed"
    availability_zones  = ["1"]
    upgrade_settings = {
      max_surge = "10%"
    }
  }
  
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  acr_id                    = module.container_registry.acr_id
  
  tags = {
    Environment = "development"
    Project     = "aks-demo"
  }
}
```

### Production AKS with Multiple Node Pools
```hcl
module "aks" {
  source = "./modules/aks"
  
  environment         = "prod"
  resource_group_name = "rg-aks-prod"
  location           = "East US"
  cluster_name       = "aks-prod-cluster"
  dns_prefix         = "aks-prod"
  kubernetes_version = "1.28.3"
  sku_tier          = "Paid"
  
  # Network Configuration
  vnet_subnet_id = module.networking.aks_subnet_id
  network_plugin = "azure"
  network_policy = "azure"
  dns_service_ip = "10.4.0.10"
  service_cidr   = "10.4.0.0/24"
  
  # Identity
  identity_ids = [module.identity.aks_identity_id]
  
  # Advanced Features
  azure_policy_enabled            = true
  enable_key_vault_secrets_provider = true
  enable_microsoft_defender       = true
  enable_workload_identity        = true
  enable_oidc_issuer             = true
  
  # Default Node Pool
  default_node_pool = {
    name                = "default"
    node_count          = 3
    vm_size             = "Standard_D4s_v3"
    enable_auto_scaling = true
    min_count           = 3
    max_count           = 10
    max_pods            = 50
    os_disk_size_gb     = 256
    os_disk_type        = "Managed"
    availability_zones  = ["1", "2", "3"]
    upgrade_settings = {
      max_surge = "33%"
    }
  }
  
  # Additional Node Pools
  additional_node_pools = {
    system = {
      vm_size             = "Standard_D4s_v3"
      node_count          = 3
      enable_auto_scaling = true
      min_count           = 3
      max_count           = 5
      max_pods            = 50
      os_disk_size_gb     = 256
      os_disk_type        = "Managed"
      os_type             = "Linux"
      node_taints         = ["CriticalAddonsOnly=true:NoSchedule"]
      node_labels = {
        "node-type" = "system"
        "workload"  = "system"
      }
      availability_zones = ["1", "2", "3"]
      priority           = "Regular"
      eviction_policy    = ""
      spot_max_price     = -1
      tags = {
        NodePool = "system"
      }
      upgrade_settings = {
        max_surge = "33%"
      }
    }
    
    spot = {
      vm_size             = "Standard_D4s_v3"
      node_count          = 2
      enable_auto_scaling = true
      min_count           = 0
      max_count           = 10
      max_pods            = 50
      os_disk_size_gb     = 256
      os_disk_type        = "Managed"
      os_type             = "Linux"
      node_taints         = ["kubernetes.azure.com/scalesetpriority=spot:NoSchedule"]
      node_labels = {
        "kubernetes.azure.com/scalesetpriority" = "spot"
        "workload" = "batch"
      }
      availability_zones = ["1", "2", "3"]
      priority           = "Spot"
      eviction_policy    = "Delete"
      spot_max_price     = 0.1
      tags = {
        NodePool = "spot"
      }
      upgrade_settings = {
        max_surge = "33%"
      }
    }
  }
  
  # Auto Scaler Configuration
  auto_scaler_profile = {
    balance_similar_node_groups      = true
    expander                        = "least-waste"
    max_graceful_termination_sec    = "600"
    max_node_provisioning_time      = "15m"
    max_unready_nodes              = 3
    max_unready_percentage         = 45
    new_pod_scale_up_delay         = "10s"
    scale_down_delay_after_add     = "10m"
    scale_down_delay_after_delete  = "10s"
    scale_down_delay_after_failure = "3m"
    scan_interval                  = "10s"
    scale_down_unneeded           = "10m"
    scale_down_unready            = "20m"
    scale_down_utilization_threshold = 0.5
    empty_bulk_delete_max         = 10
    skip_nodes_with_local_storage = true
    skip_nodes_with_system_pods   = true
  }
  
  # Monitoring and Registry
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  acr_id                    = module.container_registry.acr_id
  
  tags = {
    Environment = "production"
    Project     = "aks-platform"
    Criticality = "high"
  }
}
```

## 🎯 Node Pool Strategies

### System Node Pool
**Purpose**: Critical system components and add-ons
```hcl
system = {
  vm_size             = "Standard_D2s_v3"
  node_taints         = ["CriticalAddonsOnly=true:NoSchedule"]
  node_labels = {
    "node-type" = "system"
  }
  # Dedicated for system pods only
}
```

### User Node Pool
**Purpose**: Application workloads
```hcl
user = {
  vm_size             = "Standard_D4s_v3"
  enable_auto_scaling = true
  min_count           = 1
  max_count           = 20
  # Scalable for application demands
}
```

### Spot Instance Node Pool
**Purpose**: Cost-optimized batch workloads
```hcl
spot = {
  priority           = "Spot"
  eviction_policy    = "Delete"
  spot_max_price     = 0.1
  node_taints        = ["kubernetes.azure.com/scalesetpriority=spot:NoSchedule"]
  # Cost-effective for fault-tolerant workloads
}
```

### GPU Node Pool
**Purpose**: Machine learning and GPU workloads
```hcl
gpu = {
  vm_size     = "Standard_NC6s_v3"
  node_taints = ["nvidia.com/gpu=true:NoSchedule"]
  node_labels = {
    "accelerator" = "nvidia-tesla-v100"
  }
  # Specialized for GPU workloads
}
```

## 🔧 Advanced Features

### Azure Policy Integration
```hcl
azure_policy_enabled = true
```
**Benefits**:
- Governance and compliance
- Security policy enforcement
- Resource standardization
- Audit and reporting

### Workload Identity
```hcl
enable_workload_identity = true
enable_oidc_issuer      = true
```
**Benefits**:
- Secure pod-to-Azure service authentication
- No stored credentials in pods
- Fine-grained access control
- Audit trail for service access

### Key Vault Secrets Provider
```hcl
enable_key_vault_secrets_provider = true
```
**Benefits**:
- Secure secret injection into pods
- Automatic secret rotation
- Centralized secret management
- Compliance with security standards

### Microsoft Defender
```hcl
enable_microsoft_defender = true
```
**Benefits**:
- Container security scanning
- Runtime threat detection
- Security recommendations
- Compliance monitoring

## 🔗 Dependencies

### Upstream Dependencies
- **resource-group** module: Resource group name and location
- **networking** module: Subnet ID for node placement
- **identity** module: User assigned identity for cluster
- **monitoring** module: Log Analytics workspace for monitoring
- **container-registry** module: ACR for container images

### Downstream Dependencies
This module provides outputs used by:
- Applications for cluster connection
- Monitoring tools for cluster metrics
- CI/CD pipelines for deployments

## 🔍 Cluster Management

### Getting Cluster Credentials
```bash
# Get credentials
az aks get-credentials --resource-group rg-aks-prod --name aks-prod-cluster

# Verify connection
kubectl get nodes
kubectl cluster-info
```

### Node Pool Management
```bash
# List node pools
az aks nodepool list --cluster-name aks-prod-cluster --resource-group rg-aks-prod

# Scale node pool
az aks nodepool scale --cluster-name aks-prod-cluster --resource-group rg-aks-prod --name user --node-count 5

# Upgrade node pool
az aks nodepool upgrade --cluster-name aks-prod-cluster --resource-group rg-aks-prod --name user --kubernetes-version 1.28.3
```

### Cluster Upgrades
```bash
# Check available versions
az aks get-versions --location "East US"

# Upgrade control plane
az aks upgrade --cluster-name aks-prod-cluster --resource-group rg-aks-prod --kubernetes-version 1.28.3

# Upgrade specific node pool
az aks nodepool upgrade --cluster-name aks-prod-cluster --resource-group rg-aks-prod --name default --kubernetes-version 1.28.3
```

## 📊 Monitoring and Observability

### Container Insights
Automatically enabled when `log_analytics_workspace_id` is provided:
- Node and pod performance metrics
- Container logs aggregation
- Cluster health monitoring
- Resource utilization tracking

### Custom Monitoring
```bash
# Install Prometheus and Grafana
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack

# Install Azure Monitor for containers
kubectl apply -f https://raw.githubusercontent.com/microsoft/OMS-docker/ci_feature_prod/Kubernetes/container-azm-ms-agentconfig.yaml
```

## 🔒 Security Best Practices

### Network Security
- Use Azure CNI for advanced networking
- Enable network policies for pod-to-pod communication
- Implement ingress controllers with TLS
- Use private clusters for sensitive workloads

### Identity and Access
- Enable Workload Identity for pod authentication
- Use Azure RBAC for cluster access control
- Implement least privilege access
- Regular audit of cluster permissions

### Container Security
- Enable Microsoft Defender for containers
- Scan images for vulnerabilities
- Use admission controllers for policy enforcement
- Implement Pod Security Standards

## 📈 Scaling and Performance

### Auto-scaling Configuration
```hcl
auto_scaler_profile = {
  scale_down_utilization_threshold = 0.5
  scale_down_unneeded             = "10m"
  scale_down_delay_after_add      = "10m"
  max_graceful_termination_sec    = "600"
}
```

### Performance Optimization
- Choose appropriate VM sizes for workloads
- Use availability zones for high availability
- Configure resource requests and limits
- Monitor and optimize cluster utilization

## 🔄 Maintenance Tasks

### Regular Maintenance
- Update Kubernetes version quarterly
- Review and update node pool configurations
- Monitor cluster health and performance
- Update add-ons and extensions

### Backup and Disaster Recovery
- Backup cluster configuration
- Document restore procedures
- Test disaster recovery scenarios
- Maintain infrastructure as code

## 🤝 Contributing

When modifying this module:
1. Test with different node pool configurations
2. Validate advanced feature combinations
3. Update documentation for new features
4. Consider backward compatibility
5. Test upgrade scenarios

## 📚 References

- [Azure Kubernetes Service Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [AKS Best Practices](https://docs.microsoft.com/en-us/azure/aks/best-practices)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Azure Policy for AKS](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/policy-for-kubernetes)
