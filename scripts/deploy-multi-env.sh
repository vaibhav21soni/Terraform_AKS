#!/bin/bash

# Multi-Environment AKS Deployment Script with Simplified Workspace Support
# This script helps deploy AKS clusters across multiple environments using automatic workspace-based backend

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
TERRAFORM_VERSION="1.5.0"

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
    echo "Multi-Environment AKS Deployment Script with Simplified Workspace Support"
    echo ""
    echo "Usage: $0 [COMMAND] [ENVIRONMENT] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  deploy     Deploy infrastructure for specified environment(s)"
    echo "  destroy    Destroy infrastructure for specified environment(s)"
    echo "  plan       Create execution plan for specified environment(s)"
    echo "  validate   Validate configuration for specified environment(s)"
    echo "  status     Show status of all environments"
    echo "  workspace  Manage Terraform workspaces"
    echo "  help       Show this help message"
    echo ""
    echo "Environments:"
    echo "  dev        Development environment"
    echo "  staging    Staging environment"
    echo "  prod       Production environment"
    echo "  all        All environments"
    echo ""
    echo "Options:"
    echo "  --auto-approve    Skip interactive approval"
    echo "  --parallel        Deploy environments in parallel"
    echo "  --dry-run         Show what would be done without executing"
    echo ""
    echo "Workspace Commands:"
    echo "  workspace list                    List all workspaces"
    echo "  workspace create <env>            Create workspace for environment"
    echo "  workspace select <env>            Select workspace for environment"
    echo "  workspace delete <env>            Delete workspace for environment"
    echo "  workspace current                 Show current workspace"
    echo ""
    echo "Examples:"
    echo "  $0 deploy dev                     # Deploy development environment"
    echo "  $0 deploy all --parallel          # Deploy all environments in parallel"
    echo "  $0 workspace create dev           # Create development workspace"
    echo "  $0 plan staging                   # Plan staging environment"
    echo "  $0 destroy prod --auto-approve    # Destroy production (with auto-approve)"
    echo "  $0 status                         # Show status of all environments"
    echo ""
    echo "Note: No backend reconfiguration needed! Workspaces automatically use separate state files."
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed"
        exit 1
    fi
    
    # Check if Azure CLI is installed
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI is not installed"
        exit 1
    fi
    
    # Check if logged in to Azure
    if ! az account show &> /dev/null; then
        log_error "Not logged in to Azure CLI. Please run 'az login'"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

validate_environment() {
    local env=$1
    
    if [[ ! " ${ENVIRONMENTS[@]} " =~ " ${env} " ]] && [[ "$env" != "all" ]]; then
        log_error "Invalid environment: $env"
        log_info "Valid environments: ${ENVIRONMENTS[*]} all"
        exit 1
    fi
}

get_environments() {
    local env=$1
    
    if [[ "$env" == "all" ]]; then
        echo "${ENVIRONMENTS[@]}"
    else
        echo "$env"
    fi
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

terraform_workspace() {
    local action=$1
    local env=$2
    
    cd "$PROJECT_ROOT"
    ensure_terraform_init
    
    case "$action" in
        "list")
            log_info "Listing Terraform workspaces..."
            terraform workspace list
            ;;
        "current")
            log_info "Current workspace: $(terraform workspace show)"
            ;;
        "create")
            if [[ -z "$env" ]]; then
                log_error "Environment is required for workspace create"
                exit 1
            fi
            log_info "Creating workspace for $env environment..."
            terraform workspace new "$env" 2>/dev/null || log_warning "Workspace $env already exists"
            log_success "Workspace $env is ready"
            ;;
        "select")
            if [[ -z "$env" ]]; then
                log_error "Environment is required for workspace select"
                exit 1
            fi
            log_info "Selecting workspace for $env environment..."
            terraform workspace select "$env"
            log_success "Selected workspace: $env"
            ;;
        "delete")
            if [[ -z "$env" ]]; then
                log_error "Environment is required for workspace delete"
                exit 1
            fi
            log_info "Deleting workspace for $env environment..."
            terraform workspace select default
            terraform workspace delete "$env"
            log_success "Deleted workspace: $env"
            ;;
        *)
            log_error "Unknown workspace action: $action"
            show_help
            exit 1
            ;;
    esac
}

terraform_plan() {
    local env=$1
    local auto_approve=${2:-false}
    
    log_info "Creating Terraform plan for $env environment..."
    
    cd "$PROJECT_ROOT"
    ensure_terraform_init
    
    # Ensure workspace exists and select it
    terraform workspace new "$env" 2>/dev/null || true
    terraform workspace select "$env"
    
    local plan_file="terraform-$env.tfplan"
    local var_file="environments/$env/terraform.tfvars"
    
    if [[ ! -f "$var_file" ]]; then
        log_error "Configuration file not found: $var_file"
        return 1
    fi
    
    if terraform plan -var-file="$var_file" -out="$plan_file"; then
        log_success "Terraform plan created for $env: $plan_file"
        return 0
    else
        log_error "Terraform plan failed for $env"
        return 1
    fi
}

terraform_apply() {
    local env=$1
    local auto_approve=${2:-false}
    
    log_info "Applying Terraform configuration for $env environment..."
    
    cd "$PROJECT_ROOT"
    
    # Ensure we're in the correct workspace
    terraform workspace select "$env"
    
    local plan_file="terraform-$env.tfplan"
    
    if [[ ! -f "$plan_file" ]]; then
        log_error "Plan file not found: $plan_file. Run plan first."
        return 1
    fi
    
    if [[ "$auto_approve" == "true" ]]; then
        terraform apply "$plan_file"
    else
        echo -e "${YELLOW}About to apply changes for $env environment.${NC}"
        read -p "Do you want to continue? (yes/no): " -r
        if [[ $REPLY == "yes" ]]; then
            terraform apply "$plan_file"
        else
            log_warning "Apply cancelled for $env"
            return 1
        fi
    fi
    
    log_success "Terraform apply completed for $env"
    
    # Clean up plan file
    rm -f "$plan_file"
}

terraform_destroy() {
    local env=$1
    local auto_approve=${2:-false}
    
    log_info "Destroying Terraform infrastructure for $env environment..."
    
    cd "$PROJECT_ROOT"
    ensure_terraform_init
    
    # Ensure workspace exists and select it
    terraform workspace select "$env" 2>/dev/null || {
        log_error "Workspace $env does not exist"
        return 1
    }
    
    local var_file="environments/$env/terraform.tfvars"
    
    if [[ ! -f "$var_file" ]]; then
        log_error "Configuration file not found: $var_file"
        return 1
    fi
    
    if [[ "$auto_approve" == "true" ]]; then
        terraform destroy -var-file="$var_file" -auto-approve
    else
        echo -e "${RED}WARNING: This will destroy all resources in $env environment!${NC}"
        read -p "Type 'yes' to confirm destruction: " -r
        if [[ $REPLY == "yes" ]]; then
            terraform destroy -var-file="$var_file"
        else
            log_warning "Destroy cancelled for $env"
            return 1
        fi
    fi
    
    log_success "Terraform destroy completed for $env"
}

terraform_validate() {
    local env=$1
    
    log_info "Validating Terraform configuration for $env environment..."
    
    cd "$PROJECT_ROOT"
    ensure_terraform_init
    
    # Ensure workspace exists and select it
    terraform workspace new "$env" 2>/dev/null || true
    terraform workspace select "$env"
    
    local var_file="environments/$env/terraform.tfvars"
    
    if [[ ! -f "$var_file" ]]; then
        log_error "Configuration file not found: $var_file"
        return 1
    fi
    
    if terraform validate && terraform fmt -check; then
        log_success "Terraform validation passed for $env"
        return 0
    else
        log_error "Terraform validation failed for $env"
        return 1
    fi
}

show_status() {
    log_info "Checking status of all environments..."
    
    cd "$PROJECT_ROOT"
    ensure_terraform_init
    
    echo -e "\n${BLUE}=== Environment Status ===${NC}"
    printf "%-12s %-15s %-20s %-15s\n" "Environment" "Workspace" "Last Modified" "Resources"
    printf "%-12s %-15s %-20s %-15s\n" "----------" "---------" "-------------" "---------"
    
    for env in "${ENVIRONMENTS[@]}"; do
        local var_file="environments/$env/terraform.tfvars"
        local workspace_exists="No"
        local last_modified="N/A"
        local resource_count="0"
        
        if [[ -f "$var_file" ]]; then
            # Check if workspace exists
            if terraform workspace list | grep -q "$env"; then
                workspace_exists="Yes"
                
                # Try to get state info
                if terraform workspace select "$env" &>/dev/null; then
                    local state_info=$(terraform show -json 2>/dev/null | jq -r '.values.root_module.resources | length' 2>/dev/null || echo "Unknown")
                    resource_count="$state_info"
                    
                    # Get last modified time from state
                    local state_file=".terraform/terraform.tfstate"
                    if [[ -f "$state_file" ]]; then
                        last_modified=$(stat -c %y "$state_file" 2>/dev/null | cut -d' ' -f1 || echo "Unknown")
                    fi
                fi
            fi
            
            printf "%-12s %-15s %-20s %-15s\n" "$env" "$workspace_exists" "$last_modified" "$resource_count"
        else
            printf "%-12s %-15s %-20s %-15s\n" "$env" "No Config" "N/A" "N/A"
        fi
    done
    
    echo ""
    log_info "Current workspace: $(terraform workspace show)"
}

deploy_environment() {
    local env=$1
    local auto_approve=$2
    local dry_run=$3
    
    log_info "Starting deployment for $env environment..."
    
    if [[ "$dry_run" == "true" ]]; then
        log_info "[DRY RUN] Would deploy $env environment"
        return 0
    fi
    
    ensure_terraform_init || return 1
    terraform_workspace "create" "$env" || return 1
    terraform_workspace "select" "$env" || return 1
    terraform_plan "$env" "$auto_approve" || return 1
    terraform_apply "$env" "$auto_approve" || return 1
    
    log_success "Deployment completed for $env environment"
}

deploy_parallel() {
    local environments=("$@")
    local auto_approve=${auto_approve:-false}
    local dry_run=${dry_run:-false}
    
    log_info "Starting parallel deployment for environments: ${environments[*]}"
    
    local pids=()
    
    for env in "${environments[@]}"; do
        (
            deploy_environment "$env" "$auto_approve" "$dry_run"
        ) &
        pids+=($!)
    done
    
    # Wait for all deployments to complete
    local failed=0
    for pid in "${pids[@]}"; do
        if ! wait "$pid"; then
            ((failed++))
        fi
    done
    
    if [[ $failed -eq 0 ]]; then
        log_success "All parallel deployments completed successfully"
    else
        log_error "$failed deployment(s) failed"
        exit 1
    fi
}

# Main execution
main() {
    local command=${1:-help}
    local environment=${2:-}
    local auto_approve=false
    local parallel=false
    local dry_run=false
    
    # Parse options
    shift 2 2>/dev/null || shift $# 2>/dev/null
    while [[ $# -gt 0 ]]; do
        case $1 in
            --auto-approve)
                auto_approve=true
                shift
                ;;
            --parallel)
                parallel=true
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    case "$command" in
        "deploy")
            if [[ -z "$environment" ]]; then
                log_error "Environment is required for deploy command"
                show_help
                exit 1
            fi
            
            validate_environment "$environment"
            check_prerequisites
            
            local envs=($(get_environments "$environment"))
            
            if [[ "$parallel" == "true" && ${#envs[@]} -gt 1 ]]; then
                deploy_parallel "${envs[@]}"
            else
                for env in "${envs[@]}"; do
                    deploy_environment "$env" "$auto_approve" "$dry_run"
                done
            fi
            ;;
        "destroy")
            if [[ -z "$environment" ]]; then
                log_error "Environment is required for destroy command"
                show_help
                exit 1
            fi
            
            validate_environment "$environment"
            check_prerequisites
            
            local envs=($(get_environments "$environment"))
            
            for env in "${envs[@]}"; do
                terraform_destroy "$env" "$auto_approve"
            done
            ;;
        "plan")
            if [[ -z "$environment" ]]; then
                log_error "Environment is required for plan command"
                show_help
                exit 1
            fi
            
            validate_environment "$environment"
            check_prerequisites
            
            local envs=($(get_environments "$environment"))
            
            for env in "${envs[@]}"; do
                terraform_plan "$env"
            done
            ;;
        "validate")
            if [[ -z "$environment" ]]; then
                log_error "Environment is required for validate command"
                show_help
                exit 1
            fi
            
            validate_environment "$environment"
            
            local envs=($(get_environments "$environment"))
            
            for env in "${envs[@]}"; do
                terraform_validate "$env"
            done
            ;;
        "workspace")
            local action=$environment
            local env=$3
            terraform_workspace "$action" "$env"
            ;;
        "status")
            show_status
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

# Export variables for parallel execution
export -f log_info log_success log_warning log_error
export -f ensure_terraform_init terraform_plan terraform_apply terraform_destroy terraform_workspace
export -f deploy_environment
export PROJECT_ROOT ENVIRONMENTS

# Run main function
main "$@"
