# Monitoring Module

This module creates and manages Azure monitoring and observability resources including Log Analytics Workspace and Application Insights for comprehensive AKS cluster monitoring.

## 📋 Purpose

The Monitoring module provides comprehensive observability with:
- Centralized log collection and analysis
- Application performance monitoring
- Container insights for AKS clusters
- Custom metrics and alerting capabilities
- Integration with Azure Monitor ecosystem

## 🏗️ Resources Created

- **azurerm_log_analytics_workspace**: Centralized logging and analytics platform
- **azurerm_log_analytics_solution**: Container Insights solution for AKS monitoring
- **azurerm_application_insights**: Application performance monitoring and analytics

## 📥 Input Variables

| Variable | Type | Description | Default | Required |
|----------|------|-------------|---------|----------|
| `environment` | string | Environment name | - | ✅ |
| `resource_group_name` | string | Name of the resource group | - | ✅ |
| `location` | string | Azure region | - | ✅ |
| `cluster_name` | string | Name of the AKS cluster | - | ✅ |
| `log_analytics_workspace` | object | Log Analytics Workspace configuration | - | ✅ |
| `application_insights` | object | Application Insights configuration | - | ✅ |
| `enable_container_insights` | bool | Enable Container Insights solution | `true` | ❌ |
| `tags` | map(string) | Tags to assign to resources | `{}` | ❌ |

### Log Analytics Workspace Object Structure
```hcl
log_analytics_workspace = {
  sku               = "PerGB2018"
  retention_in_days = 30
  daily_quota_gb    = 1
}
```

### Application Insights Object Structure
```hcl
application_insights = {
  application_type                = "web"
  daily_data_cap_in_gb           = 1
  daily_data_cap_notifications_disabled = false
  retention_in_days              = 30
  sampling_percentage            = 100
}
```

## 📤 Outputs

| Output | Type | Description |
|--------|------|-------------|
| `log_analytics_workspace_id` | string | ID of the Log Analytics workspace |
| `log_analytics_workspace_name` | string | Name of the Log Analytics workspace |
| `log_analytics_workspace_workspace_id` | string | Workspace ID for Log Analytics |
| `log_analytics_workspace_primary_shared_key` | string | Primary shared key (sensitive) |
| `application_insights_id` | string | ID of Application Insights component |
| `application_insights_app_id` | string | Application ID for Application Insights |
| `application_insights_instrumentation_key` | string | Instrumentation key (sensitive) |
| `application_insights_connection_string` | string | Connection string (sensitive) |

## 🚀 Usage Examples

### Basic Monitoring Setup
```hcl
module "monitoring" {
  source = "./modules/monitoring"
  
  environment         = "dev"
  resource_group_name = "rg-aks-dev"
  location           = "East US"
  cluster_name       = "aks-dev-cluster"
  
  log_analytics_workspace = {
    sku               = "PerGB2018"
    retention_in_days = 30
    daily_quota_gb    = 1
  }
  
  application_insights = {
    application_type                = "web"
    daily_data_cap_in_gb           = 1
    daily_data_cap_notifications_disabled = false
    retention_in_days              = 30
    sampling_percentage            = 100
  }
  
  enable_container_insights = true
  
  tags = {
    Environment = "development"
    Project     = "aks-demo"
  }
}
```

### Production Monitoring with Enhanced Configuration
```hcl
module "monitoring" {
  source = "./modules/monitoring"
  
  environment         = "prod"
  resource_group_name = "rg-aks-prod"
  location           = "East US"
  cluster_name       = "aks-prod-cluster"
  
  log_analytics_workspace = {
    sku               = "PerGB2018"
    retention_in_days = 90
    daily_quota_gb    = 50
  }
  
  application_insights = {
    application_type                = "web"
    daily_data_cap_in_gb           = 50
    daily_data_cap_notifications_disabled = false
    retention_in_days              = 90
    sampling_percentage            = 100
  }
  
  enable_container_insights = true
  
  tags = {
    Environment = "production"
    Project     = "aks-platform"
    Criticality = "high"
  }
}
```

### Staging with Cost-Optimized Configuration
```hcl
module "monitoring" {
  source = "./modules/monitoring"
  
  environment         = "staging"
  resource_group_name = "rg-aks-staging"
  location           = "East US"
  cluster_name       = "aks-staging-cluster"
  
  log_analytics_workspace = {
    sku               = "PerGB2018"
    retention_in_days = 60
    daily_quota_gb    = 5
  }
  
  application_insights = {
    application_type                = "web"
    daily_data_cap_in_gb           = 5
    daily_data_cap_notifications_disabled = false
    retention_in_days              = 60
    sampling_percentage            = 100
  }
  
  enable_container_insights = true
  
  tags = {
    Environment = "staging"
    Project     = "aks-demo"
  }
}
```

## 📊 Log Analytics Workspace Features

### Data Collection
- **Container Logs**: Application and system container logs
- **Performance Metrics**: CPU, memory, disk, and network metrics
- **Kubernetes Events**: Cluster events and state changes
- **Custom Metrics**: Application-specific metrics

### Query Capabilities
```kusto
// Container CPU usage
Perf
| where ObjectName == "K8SContainer" and CounterName == "cpuUsageNanoCores"
| summarize AvgCPU = avg(CounterValue) by bin(TimeGenerated, 5m), InstanceName

// Pod restart events
KubeEvents
| where Reason == "Failed" or Reason == "FailedMount"
| project TimeGenerated, Namespace, Name, Reason, Message

// Application errors
ContainerLog
| where LogEntry contains "ERROR"
| project TimeGenerated, Computer, ContainerID, LogEntry
```

### Workspace SKUs
- **Free**: 500 MB/day, 7-day retention
- **PerGB2018**: Pay-per-GB ingested, configurable retention
- **PerNode**: Per-node pricing (legacy)
- **Premium**: Enhanced features and performance

## 📱 Application Insights Features

### Application Performance Monitoring
- **Request Tracking**: HTTP request performance and failures
- **Dependency Monitoring**: External service call tracking
- **Exception Tracking**: Automatic exception capture
- **Custom Events**: Business logic tracking

### Integration Examples
```javascript
// Node.js application
const appInsights = require('applicationinsights');
appInsights.setup('${module.monitoring.application_insights_connection_string}');
appInsights.start();

// Custom event tracking
appInsights.defaultClient.trackEvent({
  name: 'UserLogin',
  properties: { userId: '12345', method: 'oauth' }
});
```

```python
# Python application
from applicationinsights import TelemetryClient
tc = TelemetryClient('${module.monitoring.application_insights_instrumentation_key}')

# Track custom metrics
tc.track_metric('ProcessingTime', 42.0)
tc.flush()
```

### Application Types
- **web**: Web applications and APIs
- **java**: Java applications
- **Node.JS**: Node.js applications
- **other**: General purpose applications

## 🔍 Container Insights

### Cluster Monitoring
- **Node Performance**: CPU, memory, disk usage per node
- **Pod Performance**: Resource usage per pod
- **Container Performance**: Individual container metrics
- **Network Metrics**: Network traffic and connectivity

### Health Monitoring
- **Cluster Health**: Overall cluster status
- **Node Health**: Individual node status
- **Pod Health**: Pod lifecycle and status
- **Service Health**: Kubernetes service availability

### Alerting Rules
```json
{
  "name": "High CPU Usage",
  "description": "Alert when node CPU usage exceeds 80%",
  "severity": 2,
  "criteria": {
    "allOf": [
      {
        "metricName": "cpuUsagePercentage",
        "operator": "GreaterThan",
        "threshold": 80,
        "timeAggregation": "Average"
      }
    ]
  }
}
```

## 🔗 AKS Integration

### Automatic Configuration
When the monitoring module is used with AKS:
```hcl
# In AKS module
oms_agent {
  log_analytics_workspace_id = var.log_analytics_workspace_id
}
```

### Manual Configuration
```bash
# Enable monitoring on existing cluster
az aks enable-addons \
  --resource-group rg-aks-prod \
  --name aks-prod-cluster \
  --addons monitoring \
  --workspace-resource-id ${log_analytics_workspace_id}
```

### Kubernetes Deployment with Monitoring
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-app
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
    prometheus.io/path: "/metrics"
spec:
  template:
    spec:
      containers:
      - name: app
        image: sample-app:latest
        env:
        - name: APPINSIGHTS_INSTRUMENTATIONKEY
          value: "${module.monitoring.application_insights_instrumentation_key}"
```

## 📈 Custom Dashboards and Workbooks

### Azure Workbook Example
```json
{
  "version": "Notebook/1.0",
  "items": [
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "Perf | where ObjectName == \"K8SContainer\" | summarize avg(CounterValue) by bin(TimeGenerated, 5m)",
        "size": 0,
        "title": "Container CPU Usage",
        "visualization": "timechart"
      }
    }
  ]
}
```

### Grafana Integration
```bash
# Add Azure Monitor data source to Grafana
curl -X POST \
  http://grafana:3000/api/datasources \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Azure Monitor",
    "type": "grafana-azure-monitor-datasource",
    "jsonData": {
      "subscriptionId": "'${subscription_id}'",
      "tenantId": "'${tenant_id}'",
      "clientId": "'${client_id}'"
    }
  }'
```

## 🚨 Alerting and Notifications

### Log Analytics Alerts
```bash
# Create alert rule
az monitor scheduled-query create \
  --name "High Error Rate" \
  --resource-group rg-aks-prod \
  --scopes ${log_analytics_workspace_id} \
  --condition "count 'ContainerLog | where LogEntry contains \"ERROR\"' > 10" \
  --description "Alert when error rate is high" \
  --evaluation-frequency 5m \
  --window-size 15m \
  --severity 2
```

### Application Insights Alerts
```bash
# Create availability alert
az monitor metrics alert create \
  --name "App Availability" \
  --resource-group rg-aks-prod \
  --scopes ${application_insights_id} \
  --condition "avg availabilityResults/availabilityPercentage < 95" \
  --description "Alert when availability drops below 95%" \
  --evaluation-frequency 1m \
  --window-size 5m
```

### Action Groups
```bash
# Create action group for notifications
az monitor action-group create \
  --name "AKS-Alerts" \
  --resource-group rg-aks-prod \
  --short-name "AKS" \
  --email-receivers name=admin email=admin@company.com \
  --sms-receivers name=oncall phone=+1234567890
```

## 💰 Cost Management

### Data Ingestion Optimization
- Set appropriate daily quotas
- Use sampling for high-volume applications
- Configure log retention based on requirements
- Monitor data ingestion patterns

### Query Optimization
```kusto
// Efficient query - use time range filters
ContainerLog
| where TimeGenerated > ago(1h)
| where LogEntry contains "ERROR"
| take 100

// Avoid expensive operations
// Instead of: | extend parsed = parse_json(LogEntry)
// Use: | where LogEntry has "specific_field"
```

### Cost Monitoring
```bash
# Check Log Analytics usage
az monitor log-analytics workspace get-usage \
  --workspace-name ${workspace_name} \
  --resource-group rg-aks-prod

# Application Insights billing
az monitor app-insights component billing show \
  --app ${app_insights_name} \
  --resource-group rg-aks-prod
```

## 🔧 Advanced Configuration

### Custom Log Collection
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: container-azm-ms-agentconfig
  namespace: kube-system
data:
  schema-version: v1
  config-version: ver1
  log-data-collection-settings: |
    [log_collection_settings]
       [log_collection_settings.stdout]
          enabled = true
          exclude_namespaces = ["kube-system"]
       [log_collection_settings.stderr]
          enabled = true
          exclude_namespaces = ["kube-system"]
```

### Prometheus Integration
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: container-azm-ms-agentconfig
  namespace: kube-system
data:
  prometheus-data-collection-settings: |
    [prometheus_data_collection_settings.cluster]
        interval = "1m"
        monitor_kubernetes_pods = true
    [prometheus_data_collection_settings.node]
        interval = "1m"
```

## 🔍 Troubleshooting

### Common Issues

#### Data Not Appearing
```bash
# Check agent status
kubectl get pods -n kube-system | grep omsagent

# Check agent logs
kubectl logs -n kube-system -l component=oms-agent

# Verify workspace connection
az monitor log-analytics workspace show \
  --workspace-name ${workspace_name} \
  --resource-group rg-aks-prod
```

#### High Costs
```kusto
// Check data ingestion by table
Usage
| where TimeGenerated > ago(30d)
| summarize DataGB = sum(Quantity) / 1000 by DataType
| order by DataGB desc

// Identify high-volume containers
ContainerLog
| where TimeGenerated > ago(1d)
| summarize LogCount = count() by Computer, ContainerID
| order by LogCount desc
```

#### Performance Issues
```bash
# Check workspace performance
az monitor log-analytics workspace show \
  --workspace-name ${workspace_name} \
  --resource-group rg-aks-prod \
  --query "retentionInDays"

# Optimize queries
# Use time filters, avoid expensive operations
```

## 🔄 Maintenance Tasks

### Regular Maintenance
- Review and optimize log retention policies
- Monitor data ingestion and costs
- Update alert rules and thresholds
- Clean up unused workbooks and queries

### Performance Optimization
- Analyze query performance
- Optimize data collection settings
- Review sampling configurations
- Monitor workspace capacity

### Security Maintenance
- Review access permissions
- Audit query usage
- Update authentication settings
- Monitor for unauthorized access

## 🤝 Contributing

When modifying this module:
1. Test with different workspace configurations
2. Validate Application Insights integration
3. Test alerting scenarios
4. Update documentation for new features
5. Consider cost implications

## 📚 References

- [Azure Monitor Documentation](https://docs.microsoft.com/en-us/azure/azure-monitor/)
- [Log Analytics Documentation](https://docs.microsoft.com/en-us/azure/azure-monitor/logs/)
- [Application Insights Documentation](https://docs.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview)
- [Container Insights](https://docs.microsoft.com/en-us/azure/azure-monitor/containers/container-insights-overview)
- [KQL Reference](https://docs.microsoft.com/en-us/azure/data-explorer/kusto/query/)
