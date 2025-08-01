#!/bin/bash

# Simplified Terraform Workspace Manager for AKS Multi-Environment
# This script helps manage Terraform workspaces with automatic backend configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENVIRONMENTS=("dev" "staging" "prod")

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_help() {
    echo "Simplified Terraform Workspace Manager for AKS Multi-Environment"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  setup              One-time setup: initialize Terraform and create all workspaces"
    echo "  create <env>       Create workspace for specific environment"
    echo "  switch <env>       Switch to specific environment workspace"
    echo "  list               List all workspaces"
    echo "  current            Show current workspace"
    echo "  status             Show workspace status"
    echo "  cleanup            Clean up unused workspaces"
    echo "  backend-setup      Setup Azure Storage backend (one-time)"
    echo "  help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 setup                    # One-time setup of everything"
    echo "  $0 create dev               # Create development workspace"
    echo "  $0 switch prod              # Switch to production workspace"
    echo "  $0 backend-setup            # Setup Azure Storage backend"
    echo ""
    echo "Note: No backend reconfiguration needed! Workspaces automatically use separate state files."
}

ensure_terraform_init() {
    cd "$PROJECT_ROOT"
    
    # Check if Terraform is initialized
    if [[ ! -d ".terraform" ]]; then
        log_info "Initializing Terraform (one-time setup)..."
        terraform init
        log_success "Terraform initialized successfully"
    fi
}

setup_azure_backend() {
    log_info "Setting up Azure Storage backend..."
    
    read -p "Enter resource group name for Terraform state (default: rg-terraform-state): " STATE_RG
    STATE_RG=${STATE_RG:-rg-terraform-state}
    
    read -p "Enter storage account name for Terraform state (default: stterraformstate): " STATE_SA
    STATE_SA=${STATE_SA:-stterraformstate}
    
    read -p "Enter container name for Terraform state (default: tfstate): " STATE_CONTAINER
    STATE_CONTAINER=${STATE_CONTAINER:-tfstate}
    
    read -p "Enter Azure location (default: East US): " LOCATION
    LOCATION=${LOCATION:-"East US"}
    
    log_info "Creating backend resources..."
    
    # Create resource group
    if ! az group show --name "$STATE_RG" &> /dev/null; then
        az group create --name "$STATE_RG" --location "$LOCATION"
        log_success "Created resource group: $STATE_RG"
    else
        log_info "Resource group $STATE_RG already exists"
    fi
    
    # Create storage account
    if ! az storage account show --name "$STATE_SA" --resource-group "$STATE_RG" &> /dev/null; then
        az storage account create \
            --resource-group "$STATE_RG" \
            --name "$STATE_SA" \
            --sku Standard_LRS \
            --encryption-services blob \
            --https-only true \
            --min-tls-version TLS1_2
        log_success "Created storage account: $STATE_SA"
    else
        log_info "Storage account $STATE_SA already exists"
    fi
    
    # Create container
    az storage container create \
        --name "$STATE_CONTAINER" \
        --account-name "$STATE_SA" \
        --auth-mode login \
        --public-access off
    log_success "Created/verified container: $STATE_CONTAINER"
    
    # Update backend configuration in backend.tf
    cd "$PROJECT_ROOT"
    
    # Create a backup of the current backend.tf
    cp backend.tf backend.tf.backup
    
    # Update the backend configuration
    cat > backend.tf << EOF
# Dynamic Backend Configuration with Automatic Workspace Support
# This configuration automatically uses workspace-specific state files without reconfiguration

terraform {
  backend "azurerm" {
    # Static backend configuration - workspace will be appended to key automatically
    resource_group_name  = "$STATE_RG"
    storage_account_name = "$STATE_SA"
    container_name       = "$STATE_CONTAINER"
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
EOF
    
    log_success "Updated backend.tf with your Azure Storage configuration"
    log_success "Azure Storage backend setup completed!"
    echo ""
    echo "Next steps:"
    echo "1. Run: $0 setup"
    echo "2. Deploy environments using: ./scripts/deploy-multi-env.sh deploy <env>"
}

create_workspace() {
    local env=$1
    
    if [[ -z "$env" ]]; then
        log_error "Environment is required"
        exit 1
    fi
    
    if [[ ! " ${ENVIRONMENTS[@]} " =~ " ${env} " ]]; then
        log_error "Invalid environment: $env"
        log_info "Valid environments: ${ENVIRONMENTS[*]}"
        exit 1
    fi
    
    cd "$PROJECT_ROOT"
    ensure_terraform_init
    
    log_info "Creating workspace for $env environment..."
    
    # Create workspace (will show warning if already exists)
    terraform workspace new "$env" 2>/dev/null || log_warning "Workspace $env already exists"
    
    log_success "Workspace $env is ready"
}

switch_workspace() {
    local env=$1
    
    if [[ -z "$env" ]]; then
        log_error "Environment is required"
        exit 1
    fi
    
    cd "$PROJECT_ROOT"
    ensure_terraform_init
    
    log_info "Switching to $env workspace..."
    
    if terraform workspace select "$env"; then
        log_success "Switched to workspace: $env"
        log_info "Current workspace: $(terraform workspace show)"
    else
        log_error "Failed to switch to workspace: $env"
        log_info "Available workspaces:"
        terraform workspace list
        log_info "Create the workspace first: $0 create $env"
        exit 1
    fi
}

list_workspaces() {
    cd "$PROJECT_ROOT"
    ensure_terraform_init
    
    log_info "Available Terraform workspaces:"
    terraform workspace list
    
    echo ""
    log_info "Current workspace: $(terraform workspace show)"
}

show_current_workspace() {
    cd "$PROJECT_ROOT"
    ensure_terraform_init
    
    log_info "Current workspace: $(terraform workspace show)"
}

show_workspace_status() {
    cd "$PROJECT_ROOT"
    ensure_terraform_init
    
    echo -e "\n${BLUE}=== Workspace Status ===${NC}"
    printf "%-12s %-15s %-20s %-15s\n" "Environment" "Workspace" "State File" "Resources"
    printf "%-12s %-15s %-20s %-15s\n" "----------" "---------" "----------" "---------"
    
    local current_workspace=$(terraform workspace show)
    
    for env in "${ENVIRONMENTS[@]}"; do
        local workspace_exists="No"
        local state_file_exists="No"
        local resource_count="0"
        
        # Check workspace
        if terraform workspace list 2>/dev/null | grep -q "$env"; then
            workspace_exists="Yes"
            
            # Switch to workspace to check state
            if terraform workspace select "$env" &>/dev/null; then
                # Check if state has resources
                if terraform state list &>/dev/null | grep -q "."; then
                    state_file_exists="Yes"
                    resource_count=$(terraform state list 2>/dev/null | wc -l || echo "0")
                fi
            fi
        fi
        
        printf "%-12s %-15s %-20s %-15s\n" "$env" "$workspace_exists" "$state_file_exists" "$resource_count"
    done
    
    # Switch back to original workspace
    terraform workspace select "$current_workspace" &>/dev/null
    
    echo ""
    log_info "Current workspace: $current_workspace"
}

setup_all_workspaces() {
    log_info "Setting up all workspaces..."
    
    cd "$PROJECT_ROOT"
    
    # Initialize Terraform
    ensure_terraform_init
    
    # Create workspaces for each environment
    for env in "${ENVIRONMENTS[@]}"; do
        create_workspace "$env"
    done
    
    log_success "All workspaces setup completed!"
    show_workspace_status
}

cleanup_workspaces() {
    log_info "Cleaning up unused workspaces..."
    
    cd "$PROJECT_ROOT"
    ensure_terraform_init
    
    # Get list of all workspaces
    local all_workspaces=($(terraform workspace list | grep -v "default" | sed 's/\*//g' | tr -d ' '))
    
    # Find workspaces not in ENVIRONMENTS
    local unused_workspaces=()
    for workspace in "${all_workspaces[@]}"; do
        if [[ ! " ${ENVIRONMENTS[@]} " =~ " ${workspace} " ]]; then
            unused_workspaces+=("$workspace")
        fi
    done
    
    if [[ ${#unused_workspaces[@]} -eq 0 ]]; then
        log_info "No unused workspaces found"
        return
    fi
    
    log_warning "Found unused workspaces: ${unused_workspaces[*]}"
    read -p "Do you want to delete these workspaces? (yes/no): " -r
    
    if [[ $REPLY == "yes" ]]; then
        terraform workspace select default
        for workspace in "${unused_workspaces[@]}"; do
            terraform workspace delete "$workspace"
            log_success "Deleted workspace: $workspace"
        done
    else
        log_info "Cleanup cancelled"
    fi
}

# Main execution
main() {
    local command=${1:-help}
    local environment=${2:-}
    
    case "$command" in
        "setup")
            setup_all_workspaces
            ;;
        "create")
            create_workspace "$environment"
            ;;
        "switch")
            switch_workspace "$environment"
            ;;
        "list")
            list_workspaces
            ;;
        "current")
            show_current_workspace
            ;;
        "status")
            show_workspace_status
            ;;
        "cleanup")
            cleanup_workspaces
            ;;
        "backend-setup")
            setup_azure_backend
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            log_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
