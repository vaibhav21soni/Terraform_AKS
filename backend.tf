# Dynamic Backend Configuration with Automatic Workspace Support
# This configuration automatically uses workspace-specific state files without reconfiguration

terraform {
  backend "azurerm" {
    # Static backend configuration - workspace will be appended to key automatically
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterraformstate"
    container_name       = "tfstate"
    key                  = "aks/terraform.tfstate"

    # Terraform automatically appends workspace name to the key:
    # - default workspace: aks/terraform.tfstate
    # - dev workspace: aks/env:/dev/terraform.tfstate
    # - staging workspace: aks/env:/staging/terraform.tfstate  
    # - prod workspace: aks/env:/prod/terraform.tfstate
  }
}

# Alternative local backend for development/testing (comment out azurerm backend above to use)
# terraform {
#   backend "local" {
#     # Terraform automatically creates workspace-specific state files:
#     # - default workspace: terraform.tfstate
#     # - dev workspace: terraform.tfstate.d/dev/terraform.tfstate
#     # - staging workspace: terraform.tfstate.d/staging/terraform.tfstate
#     # - prod workspace: terraform.tfstate.d/prod/terraform.tfstate
#   }
# }

# How to use:
# 1. One-time setup:
#    terraform init
#
# 2. Create and switch workspaces:
#    terraform workspace new dev
#    terraform workspace new staging  
#    terraform workspace new prod
#
# 3. Switch between environments:
#    terraform workspace select dev
#    terraform apply -var-file="environments/dev/terraform.tfvars"
#
#    terraform workspace select staging
#    terraform apply -var-file="environments/staging/terraform.tfvars"
#
#    terraform workspace select prod
#    terraform apply -var-file="environments/prod/terraform.tfvars"
#
# No reconfiguration needed! Each workspace automatically gets its own state file.
