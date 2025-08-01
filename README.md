# Multi-Environment Azure Kubernetes Service (AKS) Terraform Module


## 🏗️ Architecture

```
terraform_aks/
├── main.tf                           # Root module orchestration
├── variables.tf                      # Root module variables
├── outputs.tf                        # Root module outputs
├── locals.tf                         # Local values and computations
├── versions.tf                       # Provider requirements
├── backend.tf                        # Automatic workspace-based backend
├── modules/                          # Modular resource organization
│   ├── resource-group/               # Resource Group module
│   ├── networking/                   # VNet, Subnets, NSG, NAT Gateway
│   ├── identity/                     # User Assigned Identities & RBAC
│   ├── aks/                         # AKS Cluster & Node Pools
│   ├── container-registry/           # Azure Container Registry
│   ├── storage/                     # Storage Accounts & Containers
│   └── monitoring/                  # Log Analytics & App Insights
├── environments/                     # Environment-specific configurations
│   ├── dev/terraform.tfvars         # Development environment
│   ├── staging/terraform.tfvars     # Staging environment
│   └── prod/terraform.tfvars        # Production environment
└── scripts/                         # Deployment and utility scripts
    ├── deploy-multi-env.sh          # Multi-environment deployment
    └── workspace-manager.sh         # Simplified workspace management
```

## 🚀 Key Features

### Simplified Workspace Management
- **No Backend Reconfiguration**: Switch environments without `terraform init -reconfigure`
- **Automatic State Separation**: Each workspace gets its own state file automatically
- **One-Time Setup**: Initialize once, use everywhere
- **Dynamic State Keys**: Terraform automatically manages workspace-specific state paths

### Dynamic Resource Management
- **`for_each`**: Creates multiple environments and resources dynamically
- **`count`**: Conditionally creates resources based on configuration
- **Conditional Logic**: Resources created only when enabled in configuration

### Multi-Environment Support
- **Environment-Specific Configurations**: Separate tfvars for each environment
- **Workspace-Based Deployment**: Each environment uses its own Terraform workspace
- **Parallel Deployment**: Deploy multiple environments simultaneously
- **No Reconfiguration**: Switch between environments seamlessly

## 📋 Prerequisites

1. **Azure CLI** (latest version)
2. **Terraform** >= 1.5.0
3. **kubectl** (for cluster management)

### Azure Permissions Required
- `Contributor` role on subscription or resource group
- `User Access Administrator` role for RBAC assignments
- `Storage Account Contributor` role for Terraform state storage

## 🚀 Quick Start

### 1. Clone and Setup
```bash
git clone <repository-url>
cd terraform_aks
```

### 2. One-Time Backend Setup
```bash
# Setup Azure Storage backend (one-time)
./scripts/workspace-manager.sh backend-setup

# Setup all workspaces (one-time)
./scripts/workspace-manager.sh setup
```

### 3. Deploy Environments
```bash
# Deploy development environment
./scripts/deploy-multi-env.sh deploy dev

# Deploy staging environment  
./scripts/deploy-multi-env.sh deploy staging

# Deploy production environment
./scripts/deploy-multi-env.sh deploy prod

# Deploy all environments in parallel
./scripts/deploy-multi-env.sh deploy all --parallel
```

## 🔧 Simplified Workspace Workflow

### Automatic State Management
Terraform automatically creates workspace-specific state files:

```
Azure Storage Backend:
├── aks/terraform.tfstate                    # default workspace
├── aks/env:/dev/terraform.tfstate           # dev workspace
├── aks/env:/staging/terraform.tfstate       # staging workspace
└── aks/env:/prod/terraform.tfstate          # prod workspace
```

### No Reconfiguration Needed!
```bash
# One-time initialization
terraform init

# Create workspaces (one-time)
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Switch between environments (no reconfiguration!)
terraform workspace select dev
terraform apply -var-file="environments/dev/terraform.tfvars"

terraform workspace select staging
terraform apply -var-file="environments/staging/terraform.tfvars"

terraform workspace select prod
terraform apply -var-file="environments/prod/terraform.tfvars"
```

## 🛠️ Management Commands

### Simplified Deployment Script

```bash
# Deploy specific environment
./scripts/deploy-multi-env.sh deploy dev

# Deploy all environments
./scripts/deploy-multi-env.sh deploy all

# Deploy with auto-approval
./scripts/deploy-multi-env.sh deploy staging --auto-approve

# Deploy environments in parallel
./scripts/deploy-multi-env.sh deploy all --parallel

# Plan changes
./scripts/deploy-multi-env.sh plan prod

# Validate configuration
./scripts/deploy-multi-env.sh validate all

# Show environment status
./scripts/deploy-multi-env.sh status

# Destroy environment
./scripts/deploy-multi-env.sh destroy dev --auto-approve
```

### Workspace Management

```bash
# One-time setup
./scripts/workspace-manager.sh setup

# Create specific workspace
./scripts/workspace-manager.sh create dev

# Switch to workspace
./scripts/workspace-manager.sh switch prod

# List all workspaces
./scripts/workspace-manager.sh list

# Show current workspace
./scripts/workspace-manager.sh current

# Show workspace status
./scripts/workspace-manager.sh status

# Clean up unused workspaces
./scripts/workspace-manager.sh cleanup
```

### Manual Terraform Commands

```bash
# One-time initialization
terraform init

# Create workspace (one-time per environment)
terraform workspace new dev

# Switch workspace (no reconfiguration needed!)
terraform workspace select dev

# Deploy with environment-specific variables
terraform apply -var-file="environments/dev/terraform.tfvars"

# Switch to another environment
terraform workspace select prod
terraform apply -var-file="environments/prod/terraform.tfvars"

# Show current workspace
terraform workspace show

# List all workspaces
terraform workspace list
```

## 🎯 Environment Structure

Each environment is defined with comprehensive configuration:

```hcl
environments = {
  dev = {
    # Basic Configuration
    resource_group_name = "rg-aks-dev"
    location           = "East US"
    cluster_name       = "aks-dev-cluster"
    dns_prefix         = "aks-dev"
    
    # Networking Configuration
    networking = {
      vnet_address_space            = ["10.1.0.0/16"]
      aks_subnet_address_prefixes   = ["10.1.1.0/24"]
      enable_nat_gateway           = true
      network_security_rules       = [...]
    }
    
    # AKS Configuration
    aks = {
      kubernetes_version = "1.28.3"
      sku_tier          = "Free"
      
      default_node_pool = {
        name                = "default"
        node_count          = 1
        vm_size             = "Standard_B2s"
        enable_auto_scaling = false
      }
      
      additional_node_pools = {
        system = {
          vm_size = "Standard_D2s_v3"
          node_taints = ["CriticalAddonsOnly=true:NoSchedule"]
        }
      }
    }
    
    # Container Registry
    container_registry = {
      enabled = true
      name    = "acraksdev"
      sku     = "Basic"
    }
    
    # Storage Accounts
    storage_accounts = {
      main = {
        account_tier = "Standard"
        account_replication_type = "LRS"
      }
    }
    
    # Monitoring
    monitoring = {
      log_analytics_workspace = {
        sku = "PerGB2018"
        retention_in_days = 30
      }
      application_insights = {
        application_type = "web"
      }
    }
  }
}
```

## 🔐 Security Features

### Network Security
- Network Security Groups with customizable rules
- NAT Gateway for secure outbound connectivity
- Private subnets for AKS nodes
- Network policies for pod-to-pod communication

### Identity & Access Management
- User Assigned Managed Identities
- RBAC role assignments
- Workload Identity support (optional)
- Service-to-service authentication

### Data Protection
- Secure Terraform state storage in Azure Storage
- Workspace isolation for environment separation
- Encrypted storage accounts
- Container registry with security policies

## 📊 Monitoring & Observability

### Built-in Monitoring
- **Log Analytics Workspace**: Centralized logging per environment
- **Container Insights**: AKS-specific monitoring
- **Application Insights**: Application performance monitoring
- **Azure Monitor**: Metrics and alerting

### Cross-Environment Monitoring
```kusto
// Query across multiple environments
union 
  workspace("aks-dev-cluster-law").Perf,
  workspace("aks-staging-cluster-law").Perf,
  workspace("aks-prod-cluster-law").Perf
| where ObjectName == "K8SContainer"
| summarize avg(CounterValue) by bin(TimeGenerated, 5m), Computer
```

## 🔄 CI/CD Integration

### GitHub Actions Example
```yaml
name: Deploy AKS Multi-Environment
on:
  push:
    branches: [main]
    paths: ['environments/**']

jobs:
  deploy:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        environment: [dev, staging, prod]
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v2
      with:
        terraform_version: 1.5.0
    
    - name: Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
    
    - name: Deploy Environment
      run: |
        # One-time init (if not cached)
        terraform init
        
        # Switch to environment workspace
        terraform workspace select ${{ matrix.environment }}
        
        # Deploy
        terraform apply -var-file="environments/${{ matrix.environment }}/terraform.tfvars" -auto-approve
```

## 🧪 Testing and Validation

### Configuration Validation
```bash
# Validate all environments
./scripts/deploy-multi-env.sh validate all

# Check Terraform formatting
terraform fmt -check -recursive

# Validate specific environment
terraform workspace select dev
terraform validate
```

### Environment Testing
```bash
# Test connectivity to all environments
for env in dev staging prod; do
  echo "Testing $env environment..."
  terraform workspace select $env
  # Get cluster credentials and test
  az aks get-credentials --resource-group $(terraform output -raw resource_group_name) --name $(terraform output -raw cluster_name) --overwrite-existing
  kubectl get nodes
done
```

## 🔧 Troubleshooting

### Common Issues

1. **Workspace Not Found**
   ```bash
   # Create missing workspace
   ./scripts/workspace-manager.sh create dev
   ```

2. **Backend Not Initialized**
   ```bash
   # Initialize Terraform (one-time)
   terraform init
   ```

3. **State Lock Issues**
   ```bash
   # Force unlock (use with caution)
   terraform force-unlock <lock-id>
   ```

### Debug Commands
```bash
# Show current workspace
terraform workspace show

# List all workspaces
terraform workspace list

# Show Terraform state
terraform show

# Check backend configuration
terraform init -backend=false
```

## 📈 Benefits of Simplified Workflow

### ✅ **What You Get**
- **No Reconfiguration**: Switch environments without `terraform init -reconfigure`
- **Automatic State Separation**: Each workspace gets its own state file
- **One-Time Setup**: Initialize once, use everywhere
- **Simplified Commands**: Just `terraform workspace select <env>` and deploy
- **Parallel Deployments**: Deploy multiple environments simultaneously
- **Clean State Management**: Terraform handles workspace-specific state paths

### ❌ **What You Don't Need**
- ~~Multiple backend configuration files~~
- ~~Backend reconfiguration for each environment~~
- ~~Complex initialization scripts~~
- ~~Manual state file management~~
- ~~Environment-specific Terraform directories~~

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with all environments
5. Update documentation
6. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For issues and questions:
1. Check the troubleshooting section
2. Review module-specific README files
3. Check Terraform workspace status
4. Open an issue in the repository


