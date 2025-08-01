# Environments Configuration

This directory contains environment-specific Terraform variable files that define the configuration for different deployment environments (development, staging, production).

## 📁 Directory Structure

```
environments/
├── dev/
│   └── terraform.tfvars      # Development environment configuration
├── staging/
│   └── terraform.tfvars      # Staging environment configuration
└── prod/
    └── terraform.tfvars      # Production environment configuration
```

## 🎯 Purpose

Each environment directory contains a `terraform.tfvars` file that defines:
- Environment-specific resource configurations
- Scaling parameters for different workload requirements
- Security settings appropriate for each environment
- Cost optimization settings
- Feature flags for environment-specific capabilities

## 🏗️ Environment Characteristics

### Development Environment (`dev/`)
**Purpose**: Development and testing
**Characteristics**:
- **Cost-Optimized**: Minimal resources to reduce costs
- **Single Node**: Basic node configuration
- **Basic Security**: Simplified security for development ease
- **Local Storage**: Standard storage tiers
- **Basic Monitoring**: Essential monitoring only

**Key Features**:
- Single AKS node with auto-scaling disabled
- Basic ACR with admin access enabled
- Standard storage with LRS replication
- No Key Vault (optional)
- Basic monitoring with 30-day retention

### Staging Environment (`staging/`)
**Purpose**: Pre-production testing and validation
**Characteristics**:
- **Balanced Configuration**: Moderate resources for testing
- **Multi-Node**: Auto-scaling enabled
- **Enhanced Security**: Production-like security features
- **Geo-Redundant Storage**: GRS replication
- **Comprehensive Monitoring**: Enhanced monitoring and logging

**Key Features**:
- Multi-node AKS with system and user node pools
- Standard ACR with quarantine policies
- Load balancer and DNS configuration
- Key Vault integration
- Enhanced monitoring with 60-day retention

### Production Environment (`prod/`)
**Purpose**: Live production workloads
**Characteristics**:
- **High Availability**: Multi-zone deployment
- **Premium Services**: Premium SKUs for performance
- **Advanced Security**: All security features enabled
- **Geo-Replication**: Multi-region redundancy
- **Comprehensive Monitoring**: Full observability stack

**Key Features**:
- High-availability AKS with multiple specialized node pools
- Premium ACR with geo-replication and trust policies
- Multiple storage accounts with different tiers
- Advanced security with network restrictions
- Full monitoring with 90-day retention

## 🔧 Configuration Structure

Each `terraform.tfvars` file follows this structure:

```hcl
environments = {
  <environment_name> = {
    # Basic Configuration
    resource_group_name = "rg-aks-<env>"
    location           = "East US"
    cluster_name       = "aks-<env>-cluster"
    dns_prefix         = "aks-<env>"
    tags = { ... }

    # Networking Configuration
    networking = { ... }

    # Identity Configuration
    identities = { ... }

    # AKS Configuration
    aks = { ... }

    # Container Registry Configuration
    container_registry = { ... }

    # Storage Configuration
    storage_accounts = { ... }

    # Key Vault Configuration
    key_vault = { ... }

    # Monitoring Configuration
    monitoring = { ... }

    # Load Balancer Configuration
    load_balancer = { ... }

    # DNS Configuration
    dns = { ... }
  }
}
```

## 🚀 Usage Examples

### Deploy Single Environment
```bash
# Deploy development environment
terraform apply -var-file="environments/dev/terraform.tfvars"

# Deploy staging environment
terraform apply -var-file="environments/staging/terraform.tfvars"

# Deploy production environment
terraform apply -var-file="environments/prod/terraform.tfvars"
```

### Using Deployment Script
```bash
# Deploy specific environment
./scripts/deploy-multi-env.sh deploy dev

# Deploy all environments
./scripts/deploy-multi-env.sh deploy all

# Deploy environments in parallel
./scripts/deploy-multi-env.sh deploy all --parallel
```

### Environment Switching
```bash
# Copy environment configuration to root
cp environments/dev/terraform.tfvars terraform.tfvars

# Or use directly with terraform commands
terraform plan -var-file="environments/staging/terraform.tfvars"
```

## 🔍 Environment Comparison

| Feature | Development | Staging | Production |
|---------|-------------|---------|------------|
| **AKS Nodes** | 1 (B2s) | 2-3 (D2s_v3) | 3+ (D4s_v3) |
| **Auto-scaling** | Disabled | Enabled | Enabled |
| **Node Pools** | Default only | System + User | System + User + Spot |
| **ACR SKU** | Basic | Standard | Premium |
| **ACR Admin** | Enabled | Disabled | Disabled |
| **Geo-replication** | No | No | Yes |
| **Storage Replication** | LRS | GRS | RAGRS |
| **Key Vault** | Optional | Enabled | Enabled |
| **Load Balancer** | No | Yes | Yes |
| **DNS** | No | Yes | Yes |
| **Log Retention** | 30 days | 60 days | 90 days |
| **Azure Policy** | No | Yes | Yes |
| **Defender** | No | No | Yes |
| **Network Security** | Basic | Enhanced | Advanced |

## 🔐 Security Configurations

### Development Security
```hcl
# Simplified security for development
azure_policy_enabled = false
enable_key_vault_secrets_provider = false
enable_microsoft_defender = false

# Open network access
network_rule_set = {
  default_action = "Allow"
  ip_rules       = []
  virtual_networks = []
}
```

### Staging Security
```hcl
# Production-like security for testing
azure_policy_enabled = true
enable_key_vault_secrets_provider = true
enable_microsoft_defender = false

# Controlled network access
network_rule_set = {
  default_action = "Allow"
  ip_rules       = []
  virtual_networks = []
}
```

### Production Security
```hcl
# Full security features
azure_policy_enabled = true
enable_key_vault_secrets_provider = true
enable_microsoft_defender = true

# Restricted network access
network_rule_set = {
  default_action = "Deny"
  ip_rules = [
    {
      action   = "Allow"
      ip_range = "203.0.113.0/24"  # Office network
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

## 💰 Cost Optimization by Environment

### Development Cost Optimization
- **VM Sizes**: Use B-series (burstable) VMs
- **Storage**: Standard LRS for cost savings
- **Monitoring**: Minimal retention periods
- **Features**: Disable expensive features

### Staging Cost Balance
- **VM Sizes**: Standard D-series for consistent performance
- **Storage**: GRS for data protection
- **Monitoring**: Moderate retention for testing
- **Features**: Enable key features for testing

### Production Performance Focus
- **VM Sizes**: Premium D-series or higher
- **Storage**: RAGRS for maximum protection
- **Monitoring**: Extended retention for compliance
- **Features**: All features enabled for security and performance

## 🔄 Environment Promotion

### Configuration Promotion Process
1. **Develop**: Create and test in development environment
2. **Validate**: Deploy to staging for integration testing
3. **Promote**: Deploy to production with production settings

### Automated Promotion
```yaml
# GitHub Actions example
name: Environment Promotion
on:
  push:
    branches: [main]

jobs:
  deploy-dev:
    runs-on: ubuntu-latest
    steps:
    - name: Deploy to Development
      run: ./scripts/deploy-multi-env.sh deploy dev --auto-approve

  deploy-staging:
    needs: deploy-dev
    runs-on: ubuntu-latest
    steps:
    - name: Deploy to Staging
      run: ./scripts/deploy-multi-env.sh deploy staging --auto-approve

  deploy-prod:
    needs: deploy-staging
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
    - name: Deploy to Production
      run: ./scripts/deploy-multi-env.sh deploy prod --auto-approve
```

## 🔍 Environment Validation

### Configuration Validation
```bash
# Validate all environments
./scripts/deploy-multi-env.sh validate all

# Validate specific environment
terraform validate -var-file="environments/prod/terraform.tfvars"
```

### Environment Testing
```bash
# Test development environment
kubectl --context=aks-dev-cluster get nodes

# Test staging environment
kubectl --context=aks-staging-cluster get nodes

# Test production environment
kubectl --context=aks-prod-cluster get nodes
```

## 📊 Monitoring Across Environments

### Cross-Environment Dashboards
```kusto
// Query across multiple workspaces
union 
  workspace("aks-dev-cluster-law").Perf,
  workspace("aks-staging-cluster-law").Perf,
  workspace("aks-prod-cluster-law").Perf
| where ObjectName == "K8SContainer"
| summarize avg(CounterValue) by bin(TimeGenerated, 5m), Computer
```

### Environment Health Checks
```bash
# Check all environment status
./scripts/deploy-multi-env.sh status

# Health check script
for env in dev staging prod; do
  echo "Checking $env environment..."
  kubectl --context=aks-$env-cluster get nodes
  kubectl --context=aks-$env-cluster get pods --all-namespaces
done
```

## 🔧 Customization Guidelines

### Adding New Environments
1. Create new directory: `environments/test/`
2. Copy and modify existing `terraform.tfvars`
3. Update deployment scripts
4. Add environment-specific configurations

### Modifying Existing Environments
1. Update the appropriate `terraform.tfvars` file
2. Test changes in development first
3. Validate configuration syntax
4. Apply changes using deployment scripts

### Environment-Specific Features
```hcl
# Feature flags based on environment
enable_advanced_features = var.environment == "prod" ? true : false
node_count = var.environment == "dev" ? 1 : (var.environment == "staging" ? 2 : 3)
```

## 🚨 Best Practices

### Configuration Management
- Keep environment configurations in version control
- Use consistent naming conventions across environments
- Document environment-specific decisions
- Regular review and updates of configurations

### Security Practices
- Gradually increase security from dev to prod
- Test security configurations in staging
- Use separate identities and access controls
- Regular security audits across environments

### Cost Management
- Monitor costs across all environments
- Set appropriate quotas and limits
- Regular cleanup of unused resources
- Cost alerts for unexpected usage

## 🤝 Contributing

When adding or modifying environments:
1. Follow existing naming conventions
2. Document environment-specific decisions
3. Test configurations thoroughly
4. Update deployment scripts if needed
5. Add appropriate monitoring and alerting

## 📚 References

- [Terraform Workspaces](https://www.terraform.io/docs/state/workspaces.html)
- [Azure Environment Best Practices](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/)
- [AKS Production Best Practices](https://docs.microsoft.com/en-us/azure/aks/best-practices)
- [Infrastructure as Code Best Practices](https://docs.microsoft.com/en-us/azure/architecture/framework/devops/iac)
