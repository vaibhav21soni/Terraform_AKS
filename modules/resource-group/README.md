# Resource Group Module

This module creates and manages Azure Resource Groups for the AKS infrastructure.

## 📋 Purpose

The Resource Group module provides a centralized way to create and manage Azure Resource Groups across different environments. It serves as the foundation for all other Azure resources in the AKS deployment.

## 🏗️ Resources Created

- **azurerm_resource_group**: Azure Resource Group with specified name, location, and tags

## 📥 Input Variables

| Variable | Type | Description | Default | Required |
|----------|------|-------------|---------|----------|
| `environment` | string | Environment name (dev, staging, prod) | - | ✅ |
| `resource_group_name` | string | Name of the resource group | - | ✅ |
| `location` | string | Azure region where resources will be created | - | ✅ |
| `tags` | map(string) | A map of tags to assign to the resource | `{}` | ❌ |

## 📤 Outputs

| Output | Type | Description |
|--------|------|-------------|
| `id` | string | The ID of the Resource Group |
| `name` | string | The name of the Resource Group |
| `location` | string | The location of the Resource Group |

## 🚀 Usage Examples

### Basic Usage
```hcl
module "resource_group" {
  source = "./modules/resource-group"
  
  environment         = "dev"
  resource_group_name = "rg-aks-dev"
  location           = "East US"
  
  tags = {
    Environment = "development"
    Project     = "aks-demo"
    Owner       = "platform-team"
  }
}
```

### Multi-Environment Usage
```hcl
module "resource_group" {
  source = "./modules/resource-group"
  
  for_each = var.environments
  
  environment         = each.key
  resource_group_name = each.value.resource_group_name
  location           = each.value.location
  tags               = merge(local.common_tags, each.value.tags)
}
```

### With Dynamic Naming
```hcl
module "resource_group" {
  source = "./modules/resource-group"
  
  environment         = var.environment
  resource_group_name = "rg-aks-${var.environment}-${var.project_name}"
  location           = var.location
  
  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
  }
}
```

## 🔧 Configuration Details

### Resource Group Naming Convention
The module accepts any valid Azure Resource Group name, but we recommend following these conventions:
- **Pattern**: `rg-{service}-{environment}-{region}`
- **Examples**: 
  - `rg-aks-dev-eastus`
  - `rg-aks-prod-westus2`
  - `rg-aks-staging-centralus`

### Location Support
The module supports all Azure regions. Common choices for AKS:
- **East US** (`East US`)
- **West US 2** (`West US 2`)
- **Central US** (`Central US`)
- **North Europe** (`North Europe`)
- **West Europe** (`West Europe`)

### Tagging Strategy
The module supports comprehensive tagging:
```hcl
tags = {
  Environment   = "production"
  Project       = "aks-platform"
  Owner         = "platform-team"
  CostCenter    = "engineering"
  ManagedBy     = "Terraform"
  CreatedDate   = "2024-01-15"
  Criticality   = "high"
}
```

## 🔗 Dependencies

### Upstream Dependencies
- None (this is a foundational module)

### Downstream Dependencies
This module's outputs are used by:
- **networking** module (requires resource group name and location)
- **aks** module (requires resource group name and location)
- **storage** module (requires resource group name and location)
- **monitoring** module (requires resource group name and location)
- **container-registry** module (requires resource group name and location)

## 🔍 Validation

### Input Validation
The module includes basic validation for:
- Resource group name length (1-90 characters)
- Valid Azure region names
- Tag key/value constraints

### Testing
```bash
# Validate the module
terraform init
terraform validate

# Plan with sample variables
terraform plan -var="environment=dev" \
               -var="resource_group_name=rg-aks-dev" \
               -var="location=East US"

# Format check
terraform fmt -check
```

## 🚨 Important Notes

### Resource Group Lifecycle
- **Prevention**: The module includes `prevent_destroy = false` to allow destruction during development
- **Production**: Consider setting `prevent_destroy = true` for production environments
- **Dependencies**: Ensure all resources in the resource group are destroyed before destroying the resource group

### Naming Constraints
Azure Resource Group names must:
- Be 1-90 characters long
- Contain only alphanumeric characters, periods, underscores, hyphens, and parentheses
- End with alphanumeric character or underscore
- Be unique within the subscription

### Regional Considerations
- Choose regions based on compliance requirements
- Consider data residency laws
- Evaluate service availability in target regions
- Plan for disaster recovery across regions

## 📊 Cost Considerations

Resource Groups themselves have no direct cost, but consider:
- **Regional Pricing**: Different regions have different pricing
- **Data Transfer**: Cross-region data transfer costs
- **Compliance**: Some regions may have premium pricing for compliance features

## 🔄 Lifecycle Management

### Creation
```bash
terraform apply
```

### Updates
Resource group properties that can be updated:
- Tags (can be modified without recreation)
- Location (requires recreation - not recommended)

### Destruction
```bash
# Ensure all resources in the RG are destroyed first
terraform destroy
```

## 🤝 Contributing

When modifying this module:
1. Maintain backward compatibility
2. Update documentation
3. Add validation for new variables
4. Test with multiple environments
5. Update examples

## 📚 References

- [Azure Resource Groups Documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal)
- [Terraform azurerm_resource_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group)
- [Azure Naming Conventions](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging)
