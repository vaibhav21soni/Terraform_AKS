# Scripts Directory

This directory contains automation scripts for deploying, managing, and maintaining the multi-environment AKS infrastructure.

## 📁 Directory Structure

```
scripts/
└── deploy-multi-env.sh      # Multi-environment deployment and management script
```

## 🎯 Purpose

The scripts in this directory provide:
- Automated deployment workflows
- Multi-environment management capabilities
- Validation and testing automation
- Operational maintenance tasks
- CI/CD integration support

## 🚀 Main Script: deploy-multi-env.sh

The primary script for managing multi-environment AKS deployments with comprehensive functionality.

### Features
- **Multi-Environment Support**: Deploy to dev, staging, prod, or all environments
- **Parallel Deployment**: Deploy multiple environments simultaneously
- **Validation**: Pre-deployment configuration validation
- **Status Monitoring**: Check deployment status across environments
- **Error Handling**: Comprehensive error handling and rollback capabilities
- **Logging**: Detailed logging and progress tracking

### Prerequisites
- **Azure CLI**: Latest version installed and configured
- **Terraform**: Version 1.5.0 or higher
- **kubectl**: For cluster management (optional)
- **jq**: For JSON processing (optional)

## 📋 Command Reference

### Basic Commands

#### Deploy Commands
```bash
# Deploy single environment
./scripts/deploy-multi-env.sh deploy dev

# Deploy specific environment with auto-approval
./scripts/deploy-multi-env.sh deploy staging --auto-approve

# Deploy all environments sequentially
./scripts/deploy-multi-env.sh deploy all

# Deploy all environments in parallel
./scripts/deploy-multi-env.sh deploy all --parallel

# Dry run (show what would be done)
./scripts/deploy-multi-env.sh deploy prod --dry-run
```

#### Planning Commands
```bash
# Plan changes for single environment
./scripts/deploy-multi-env.sh plan dev

# Plan changes for all environments
./scripts/deploy-multi-env.sh plan all
```

#### Validation Commands
```bash
# Validate single environment configuration
./scripts/deploy-multi-env.sh validate dev

# Validate all environment configurations
./scripts/deploy-multi-env.sh validate all
```

#### Status and Monitoring
```bash
# Show status of all environments
./scripts/deploy-multi-env.sh status

# Check deployment health
./scripts/deploy-multi-env.sh health
```

#### Destruction Commands
```bash
# Destroy single environment
./scripts/deploy-multi-env.sh destroy dev

# Destroy with auto-approval (dangerous!)
./scripts/deploy-multi-env.sh destroy staging --auto-approve
```

### Advanced Usage

#### Parallel Deployment
```bash
# Deploy multiple specific environments in parallel
./scripts/deploy-multi-env.sh deploy "dev staging" --parallel

# Deploy all environments with maximum parallelism
./scripts/deploy-multi-env.sh deploy all --parallel --max-parallel=3
```

#### Environment-Specific Operations
```bash
# Deploy only if environment doesn't exist
./scripts/deploy-multi-env.sh deploy dev --if-not-exists

# Force deployment even if no changes detected
./scripts/deploy-multi-env.sh deploy prod --force

# Deploy with specific Terraform version
./scripts/deploy-multi-env.sh deploy staging --terraform-version=1.5.0
```

## 🔧 Script Configuration

### Environment Variables
```bash
# Set default environment
export DEFAULT_ENVIRONMENT=dev

# Set Terraform version
export TERRAFORM_VERSION=1.5.0

# Set Azure subscription
export AZURE_SUBSCRIPTION_ID=your-subscription-id

# Enable debug mode
export DEBUG=true

# Set parallel deployment limit
export MAX_PARALLEL_DEPLOYMENTS=3
```

### Configuration Files
The script reads configuration from:
- `environments/{env}/terraform.tfvars` - Environment-specific variables
- `.env` - Local environment variables (if present)
- Azure CLI configuration for authentication

## 📊 Script Output and Logging

### Output Format
```
[INFO] Starting deployment for dev environment...
[SUCCESS] Terraform initialized successfully
[INFO] Creating execution plan...
[SUCCESS] Terraform plan created: terraform-dev.tfplan
[INFO] Applying Terraform configuration...
[SUCCESS] Terraform apply completed successfully
[INFO] Getting AKS credentials...
[SUCCESS] kubectl configured for aks-dev-cluster
[SUCCESS] Deployment completed for dev environment
```

### Log Files
- `deploy-{environment}-{timestamp}.log` - Detailed deployment logs
- `error-{environment}-{timestamp}.log` - Error logs for troubleshooting
- `terraform-{environment}.log` - Terraform-specific logs

### Status Reporting
```
=== Environment Status ===
Environment  Status       Last Modified    Resources
----------   ------       -------------    ---------
dev          Deployed     2024-01-15       25
staging      Deployed     2024-01-14       32
prod         Deployed     2024-01-13       45
```

## 🔍 Error Handling and Troubleshooting

### Common Error Scenarios

#### Authentication Issues
```bash
# Error: Not logged in to Azure CLI
[ERROR] Not logged in to Azure CLI. Please run 'az login'

# Solution: Login to Azure
az login
```

#### Resource Conflicts
```bash
# Error: Resource already exists
[ERROR] Resource group 'rg-aks-dev' already exists

# Solution: Use force flag or destroy existing resources
./scripts/deploy-multi-env.sh deploy dev --force
```

#### Network Connectivity
```bash
# Error: Cannot connect to Terraform backend
[ERROR] Failed to initialize Terraform backend

# Solution: Check network connectivity and backend configuration
```

### Debug Mode
```bash
# Enable verbose logging
./scripts/deploy-multi-env.sh deploy dev --debug

# Enable Terraform debug logging
export TF_LOG=DEBUG
./scripts/deploy-multi-env.sh deploy dev
```

### Recovery Procedures
```bash
# Recover from failed deployment
./scripts/deploy-multi-env.sh recover dev

# Force unlock Terraform state
./scripts/deploy-multi-env.sh unlock dev

# Rollback to previous state
./scripts/deploy-multi-env.sh rollback dev
```

## 🔄 CI/CD Integration

### GitHub Actions Integration
```yaml
name: Deploy AKS Infrastructure
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
    
    - name: Setup Azure CLI
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
    
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v2
      with:
        terraform_version: 1.5.0
    
    - name: Deploy Environment
      run: |
        chmod +x scripts/deploy-multi-env.sh
        ./scripts/deploy-multi-env.sh deploy ${{ matrix.environment }} --auto-approve
```

### Azure DevOps Integration
```yaml
trigger:
  branches:
    include:
    - main
  paths:
    include:
    - environments/*

pool:
  vmImage: 'ubuntu-latest'

stages:
- stage: Deploy
  jobs:
  - job: DeployEnvironments
    strategy:
      matrix:
        dev:
          environment: 'dev'
        staging:
          environment: 'staging'
        prod:
          environment: 'prod'
    steps:
    - task: AzureCLI@2
      inputs:
        azureSubscription: 'Azure-Connection'
        scriptType: 'bash'
        scriptLocation: 'inlineScript'
        inlineScript: |
          chmod +x scripts/deploy-multi-env.sh
          ./scripts/deploy-multi-env.sh deploy $(environment) --auto-approve
```

### Jenkins Integration
```groovy
pipeline {
    agent any
    
    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'staging', 'prod', 'all'],
            description: 'Environment to deploy'
        )
        booleanParam(
            name: 'PARALLEL',
            defaultValue: false,
            description: 'Deploy environments in parallel'
        )
    }
    
    stages {
        stage('Deploy') {
            steps {
                script {
                    def parallelFlag = params.PARALLEL ? '--parallel' : ''
                    sh """
                        chmod +x scripts/deploy-multi-env.sh
                        ./scripts/deploy-multi-env.sh deploy ${params.ENVIRONMENT} --auto-approve ${parallelFlag}
                    """
                }
            }
        }
    }
}
```

## 🔒 Security Considerations

### Credential Management
- Use Azure CLI authentication or service principals
- Store sensitive variables in secure vaults
- Rotate credentials regularly
- Use least privilege access

### Script Security
```bash
# Validate script integrity
sha256sum scripts/deploy-multi-env.sh

# Run with restricted permissions
chmod 750 scripts/deploy-multi-env.sh

# Use secure temporary directories
export TMPDIR=/secure/tmp
```

### Audit Logging
```bash
# Enable audit logging
export AUDIT_LOG=true

# Log all commands
set -x
./scripts/deploy-multi-env.sh deploy prod
set +x
```

## 📈 Performance Optimization

### Parallel Deployment Tuning
```bash
# Optimize for CPU cores
export MAX_PARALLEL_DEPLOYMENTS=$(nproc)

# Optimize for network bandwidth
export MAX_PARALLEL_DEPLOYMENTS=2

# Custom optimization
export MAX_PARALLEL_DEPLOYMENTS=4
```

### Caching Strategies
```bash
# Enable Terraform plugin caching
export TF_PLUGIN_CACHE_DIR=$HOME/.terraform.d/plugin-cache

# Enable Azure CLI caching
az config set core.enable_broker_on_windows=false
```

## 🔄 Maintenance and Updates

### Script Updates
```bash
# Check for script updates
./scripts/deploy-multi-env.sh version

# Update script dependencies
./scripts/deploy-multi-env.sh update

# Validate script after updates
./scripts/deploy-multi-env.sh validate-script
```

### Regular Maintenance Tasks
```bash
# Clean up old plan files
./scripts/deploy-multi-env.sh cleanup

# Update Terraform providers
./scripts/deploy-multi-env.sh update-providers

# Health check all environments
./scripts/deploy-multi-env.sh health-check all
```

## 🤝 Contributing

### Adding New Scripts
1. Follow the existing naming convention
2. Include comprehensive error handling
3. Add help documentation
4. Test with all environments
5. Update this README

### Script Standards
- Use bash for shell scripts
- Include proper error handling
- Provide verbose logging options
- Support dry-run mode
- Include help documentation

### Testing Scripts
```bash
# Test script syntax
bash -n scripts/deploy-multi-env.sh

# Test with shellcheck
shellcheck scripts/deploy-multi-env.sh

# Test functionality
./scripts/deploy-multi-env.sh deploy dev --dry-run
```

## 📚 References

- [Bash Scripting Best Practices](https://google.github.io/styleguide/shellguide.html)
- [Terraform CLI Documentation](https://www.terraform.io/docs/cli/index.html)
- [Azure CLI Reference](https://docs.microsoft.com/en-us/cli/azure/)
- [CI/CD Best Practices](https://docs.microsoft.com/en-us/azure/devops/learn/what-is-continuous-integration)
