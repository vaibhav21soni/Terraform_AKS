# Azure Backend Setup Guide

## 🔄 Backend Configuration Restored

The Terraform configuration has been switched back to use **Azure Blob Storage** as the backend for production use.

## 📋 Prerequisites

Before using the Azure backend, ensure you have:

1. **Azure CLI** installed and authenticated
2. **Azure Storage Account** for Terraform state
3. **Proper permissions** on the storage account

## 🚀 Quick Setup

### 1. Login to Azure
```bash
# Login with device code (recommended for MFA)
az login --use-device-code

# Or login with specific tenant
az login --tenant YOUR_TENANT_ID
```

### 2. Create Backend Storage (One-time setup)
```bash
# Set variables
RESOURCE_GROUP_NAME="rg-terraform-state"
STORAGE_ACCOUNT_NAME="stterraformstate"
CONTAINER_NAME="tfstate"
LOCATION="East US"

# Create resource group
az group create --name $RESOURCE_GROUP_NAME --location "$LOCATION"

# Create storage account
az storage account create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $STORAGE_ACCOUNT_NAME \
  --sku Standard_LRS \
  --encryption-services blob

# Create container
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT_NAME
```

### 3. Initialize Terraform with Azure Backend
```bash
# Initialize with Azure backend
terraform init

# The backend configuration will automatically use:
# - Resource Group: rg-terraform-state
# - Storage Account: stterraformstate  
# - Container: tfstate
# - Key: aks/terraform.tfstate
```

## 🏗️ Workspace-Based Deployment

### Create and Use Workspaces
```bash
# Create workspaces (one-time)
terraform workspace new dev
terraform workspace new staging  
terraform workspace new prod

# Switch to desired environment
terraform workspace select dev

# Deploy to selected environment
terraform apply -var-file="environments/dev/terraform.tfvars"
```

### Automatic State File Separation
Terraform automatically creates separate state files for each workspace:

```
Azure Storage Container (tfstate):
├── aks/terraform.tfstate                    # default workspace
├── aks/env:/dev/terraform.tfstate           # dev workspace  
├── aks/env:/staging/terraform.tfstate       # staging workspace
└── aks/env:/prod/terraform.tfstate          # prod workspace
```

## 🔧 Deployment Commands

### Deploy Development Environment
```bash
terraform workspace select dev
terraform plan -var-file="environments/dev/terraform.tfvars"
terraform apply -var-file="environments/dev/terraform.tfvars"
```

### Deploy Staging Environment  
```bash
terraform workspace select staging
terraform plan -var-file="environments/staging/terraform.tfvars"
terraform apply -var-file="environments/staging/terraform.tfvars"
```

### Deploy Production Environment
```bash
terraform workspace select prod
terraform plan -var-file="environments/prod/terraform.tfvars"  
terraform apply -var-file="environments/prod/terraform.tfvars"
```

## 🛠️ Using Deployment Scripts

### Automated Deployment
```bash
# Deploy specific environment
./scripts/deploy-multi-env.sh deploy dev

# Deploy all environments
./scripts/deploy-multi-env.sh deploy all

# Deploy with auto-approval
./scripts/deploy-multi-env.sh deploy staging --auto-approve
```

### Workspace Management
```bash
# Setup all workspaces (one-time)
./scripts/workspace-manager.sh setup

# Switch workspace
./scripts/workspace-manager.sh switch prod

# Show current workspace
./scripts/workspace-manager.sh current

# List all workspaces
./scripts/workspace-manager.sh list
```

## 🔍 Verification Commands

### Check Current Configuration
```bash
# Show current workspace
terraform workspace show

# List all workspaces  
terraform workspace list

# Show backend configuration
terraform init -backend=false
```

### Validate Configuration
```bash
# Validate Terraform configuration
terraform validate

# Check formatting
terraform fmt -check -recursive

# Plan without applying
terraform plan -var-file="environments/dev/terraform.tfvars"
```

## 🚨 Important Notes

### State File Security
- ✅ State files are stored securely in Azure Blob Storage
- ✅ Each environment has isolated state files
- ✅ Access controlled through Azure RBAC
- ✅ Encryption at rest enabled by default

### Workspace Isolation
- ✅ **Complete isolation** between environments
- ✅ **No cross-environment dependencies**
- ✅ **Independent resource lifecycle**
- ✅ **Separate state management**

### Best Practices
- 🔒 **Always use workspaces** for environment separation
- 🔒 **Never commit state files** to version control
- 🔒 **Use service principals** for CI/CD pipelines
- 🔒 **Enable state locking** (automatic with Azure backend)
- 🔒 **Regular state backups** (automatic with Azure Storage)

## 🆘 Troubleshooting

### Backend Initialization Issues
```bash
# Clear Terraform cache
rm -rf .terraform/

# Re-initialize
terraform init

# Force reconfigure if needed
terraform init -reconfigure
```

### State Lock Issues
```bash
# Check for locks
az storage blob list --container-name tfstate --account-name stterraformstate

# Force unlock (use with caution)
terraform force-unlock <lock-id>
```

### Workspace Issues
```bash
# Create missing workspace
terraform workspace new <environment>

# Delete unused workspace
terraform workspace delete <environment>
```

## 📞 Support

If you encounter issues:
1. Check Azure CLI authentication: `az account show`
2. Verify storage account access: `az storage account show --name stterraformstate`
3. Confirm workspace selection: `terraform workspace show`
4. Review Terraform logs: `TF_LOG=DEBUG terraform plan`

---

