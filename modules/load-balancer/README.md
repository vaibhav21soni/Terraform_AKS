# Load Balancer Module

This module creates and manages Azure Load Balancers with support for both public and internal load balancers, including backend pools, health probes, load balancing rules, NAT rules, and outbound rules.

## Features

- **Public Load Balancers**: Internet-facing load balancers with public IP addresses
- **Internal Load Balancers**: Private load balancers within virtual networks
- **Backend Pools**: Manage backend address pools with specific VM assignments
- **Health Probes**: Configure health checks for backend services
- **Load Balancing Rules**: Define traffic distribution rules
- **NAT Rules**: Configure inbound NAT rules for specific ports
- **Outbound Rules**: Configure outbound connectivity (Standard SKU)
- **High Availability**: Support for availability zones and redundancy

## Resources Created

- `azurerm_public_ip` - Public IP addresses for public load balancers
- `azurerm_lb` - Load balancer instances
- `azurerm_lb_backend_address_pool` - Backend address pools
- `azurerm_lb_probe` - Health probes
- `azurerm_lb_rule` - Load balancing rules
- `azurerm_lb_nat_rule` - NAT rules
- `azurerm_lb_outbound_rule` - Outbound rules (Standard SKU)
- `azurerm_lb_backend_address_pool_address` - Specific backend addresses

## Usage

### Basic Public Load Balancer
```hcl
module "load_balancer" {
  source = "./modules/load-balancer"

  environment         = "dev"
  resource_group_name = "rg-aks-dev"
  location           = "East US"

  load_balancers = {
    web = {
      type                           = "public"
      sku                           = "Standard"
      sku_tier                      = "Regional"
      subnet_id                     = null
      private_ip_address_allocation = null
      private_ip_address            = null
      private_ip_address_version    = "IPv4"
      availability_zones            = ["1", "2", "3"]
      
      public_ip_allocation_method = "Static"
      public_ip_sku              = "Standard"
      domain_name_label          = "myapp-dev"

      backend_pools = [{
        name = "web-servers"
        addresses = []
      }]

      health_probes = [{
        name                = "http-probe"
        protocol            = "Http"
        port                = 80
        request_path        = "/health"
        interval_in_seconds = 15
        number_of_probes    = 2
      }]

      load_balancing_rules = [{
        name                    = "http-rule"
        backend_pool_name       = "web-servers"
        probe_name              = "http-probe"
        protocol                = "Tcp"
        frontend_port           = 80
        backend_port            = 80
        enable_floating_ip      = false
        idle_timeout_in_minutes = 4
        load_distribution       = "Default"
        disable_outbound_snat   = false
        enable_tcp_reset        = true
      }]

      nat_rules = []
      outbound_rules = []
      tags = { Service = "web" }
    }
  }

  tags = {
    Environment = "dev"
    Project     = "aks-infrastructure"
  }
}
```

### Internal Load Balancer
```hcl
module "load_balancer" {
  source = "./modules/load-balancer"

  environment         = "prod"
  resource_group_name = "rg-aks-prod"
  location           = "East US"

  load_balancers = {
    internal = {
      type                           = "internal"
      sku                           = "Standard"
      sku_tier                      = "Regional"
      subnet_id                     = var.internal_subnet_id
      private_ip_address_allocation = "Static"
      private_ip_address            = "10.0.1.100"
      private_ip_address_version    = "IPv4"
      availability_zones            = ["1", "2", "3"]
      
      public_ip_allocation_method = null
      public_ip_sku              = null
      domain_name_label          = null

      backend_pools = [{
        name = "api-servers"
        addresses = [{
          name               = "api-server-1"
          virtual_network_id = var.vnet_id
          ip_address         = "10.0.1.10"
        }, {
          name               = "api-server-2"
          virtual_network_id = var.vnet_id
          ip_address         = "10.0.1.11"
        }]
      }]

      health_probes = [{
        name                = "api-probe"
        protocol            = "Https"
        port                = 443
        request_path        = "/api/health"
        interval_in_seconds = 30
        number_of_probes    = 3
      }]

      load_balancing_rules = [{
        name                    = "api-rule"
        backend_pool_name       = "api-servers"
        probe_name              = "api-probe"
        protocol                = "Tcp"
        frontend_port           = 443
        backend_port            = 443
        enable_floating_ip      = false
        idle_timeout_in_minutes = 15
        load_distribution       = "SourceIP"
        disable_outbound_snat   = false
        enable_tcp_reset        = true
      }]

      nat_rules = []
      outbound_rules = []
      tags = { Service = "api" }
    }
  }

  tags = {
    Environment = "prod"
    Project     = "aks-infrastructure"
  }
}
```

### Advanced Load Balancer with NAT and Outbound Rules
```hcl
module "load_balancer" {
  source = "./modules/load-balancer"

  environment         = "prod"
  resource_group_name = "rg-aks-prod"
  location           = "East US"

  load_balancers = {
    advanced = {
      type                           = "public"
      sku                           = "Standard"
      sku_tier                      = "Regional"
      subnet_id                     = null
      private_ip_address_allocation = null
      private_ip_address            = null
      private_ip_address_version    = "IPv4"
      availability_zones            = ["1", "2", "3"]
      
      public_ip_allocation_method = "Static"
      public_ip_sku              = "Standard"
      domain_name_label          = "myapp-prod"

      backend_pools = [{
        name = "app-servers"
        addresses = []
      }, {
        name = "outbound-pool"
        addresses = []
      }]

      health_probes = [{
        name                = "app-probe"
        protocol            = "Http"
        port                = 8080
        request_path        = "/health"
        interval_in_seconds = 15
        number_of_probes    = 2
      }]

      load_balancing_rules = [{
        name                    = "app-rule"
        backend_pool_name       = "app-servers"
        probe_name              = "app-probe"
        protocol                = "Tcp"
        frontend_port           = 80
        backend_port            = 8080
        enable_floating_ip      = false
        idle_timeout_in_minutes = 4
        load_distribution       = "Default"
        disable_outbound_snat   = true
        enable_tcp_reset        = true
      }]

      nat_rules = [{
        name                    = "ssh-nat"
        protocol                = "Tcp"
        frontend_port           = 2222
        backend_port            = 22
        enable_floating_ip      = false
        enable_tcp_reset        = true
        idle_timeout_in_minutes = 4
      }]

      outbound_rules = [{
        name                     = "outbound-rule"
        backend_pool_name        = "outbound-pool"
        protocol                 = "All"
        enable_tcp_reset         = true
        allocated_outbound_ports = 1024
        idle_timeout_in_minutes  = 4
      }]

      tags = { Service = "application" }
    }
  }

  tags = {
    Environment = "prod"
    Project     = "aks-infrastructure"
  }
}
```

## Load Balancer Types

### Public Load Balancer
- **Internet-facing**: Accessible from the internet
- **Public IP**: Requires a public IP address
- **Use Cases**: Web applications, APIs, public services
- **Frontend**: Public IP address

### Internal Load Balancer
- **Private**: Only accessible within the virtual network
- **Private IP**: Uses a private IP address from the subnet
- **Use Cases**: Internal services, databases, microservices
- **Frontend**: Private IP address from subnet

## SKU Comparison

### Basic SKU
- **Availability**: Single availability zone
- **Backend Pool Size**: Up to 300 instances
- **Health Probes**: HTTP, HTTPS, TCP
- **SLA**: 99.95%
- **Cost**: Lower cost

### Standard SKU
- **Availability**: Zone-redundant and zonal
- **Backend Pool Size**: Up to 1000 instances
- **Health Probes**: HTTP, HTTPS, TCP
- **Outbound Rules**: Supported
- **SLA**: 99.99%
- **Security**: Secure by default

## Health Probes

Configure health probes to monitor backend service health:

### HTTP/HTTPS Probes
```hcl
health_probes = [{
  name                = "web-probe"
  protocol            = "Http"
  port                = 80
  request_path        = "/health"
  interval_in_seconds = 15
  number_of_probes    = 2
}]
```

### TCP Probes
```hcl
health_probes = [{
  name                = "tcp-probe"
  protocol            = "Tcp"
  port                = 443
  request_path        = null
  interval_in_seconds = 15
  number_of_probes    = 2
}]
```

## Load Distribution Methods

### Default
- **5-tuple hash**: Source IP, source port, destination IP, destination port, protocol
- **Use Case**: General load balancing

### Source IP (2-tuple)
- **2-tuple hash**: Source IP, destination IP
- **Use Case**: Session affinity, sticky sessions

### Source IP Protocol (3-tuple)
- **3-tuple hash**: Source IP, destination IP, protocol
- **Use Case**: Enhanced session affinity

## Integration with AKS

### Kubernetes Service Integration
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-resource-group: "rg-aks-prod"
    service.beta.kubernetes.io/azure-load-balancer-internal: "true"
    service.beta.kubernetes.io/azure-load-balancer-internal-subnet: "internal-subnet"
spec:
  type: LoadBalancer
  loadBalancerIP: "10.0.1.100"
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app: web-app
```

### NGINX Ingress Controller
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-ingress-controller
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-resource-group: "rg-aks-prod"
spec:
  type: LoadBalancer
  loadBalancerIP: "203.0.113.10"
  ports:
  - name: http
    port: 80
    targetPort: 80
  - name: https
    port: 443
    targetPort: 443
  selector:
    app: nginx-ingress-controller
```

## Security Considerations

### Network Security Groups
Ensure NSG rules allow traffic to load balancer ports:

```hcl
# Allow HTTP traffic
{
  name                       = "AllowHTTP"
  priority                   = 1001
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "80"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
}
```

### Private Endpoints
For internal load balancers, consider using private endpoints for additional security.

## Monitoring and Diagnostics

### Azure Monitor Metrics
- **Data Path Availability**: Percentage of time the data path is available
- **Health Probe Status**: Health probe success rate
- **Byte Count**: Total bytes processed
- **Packet Count**: Total packets processed
- **SNAT Connection Count**: Number of SNAT connections

### Log Analytics Integration
```hcl
# Enable diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "lb" {
  name                       = "lb-diagnostics"
  target_resource_id         = module.load_balancer.load_balancers["web"].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "LoadBalancerAlertEvent"
  }

  enabled_log {
    category = "LoadBalancerProbeHealthStatus"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment name | `string` | n/a | yes |
| resource_group_name | Name of the resource group | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| load_balancers | Map of load balancers to create | `map(object)` | `{}` | no |
| tags | A map of tags to assign to the resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| load_balancers | Map of created load balancers |
| public_ips | Map of created public IPs |
| backend_address_pools | Map of created backend address pools |
| health_probes | Map of created health probes |
| load_balancing_rules | Map of created load balancing rules |
| nat_rules | Map of created NAT rules |
| outbound_rules | Map of created outbound rules |
| backend_pool_addresses | Map of created backend pool addresses |

## Examples

### Simple Web Load Balancer
```hcl
module "web_lb" {
  source = "./modules/load-balancer"

  environment         = "prod"
  resource_group_name = "rg-web-prod"
  location           = "East US"

  load_balancers = {
    web = {
      type = "public"
      sku  = "Standard"
      sku_tier = "Regional"
      availability_zones = ["1", "2", "3"]
      
      public_ip_allocation_method = "Static"
      public_ip_sku = "Standard"
      domain_name_label = "mywebapp"

      backend_pools = [{
        name = "web-servers"
        addresses = []
      }]

      health_probes = [{
        name = "http-health"
        protocol = "Http"
        port = 80
        request_path = "/"
        interval_in_seconds = 30
        number_of_probes = 2
      }]

      load_balancing_rules = [{
        name = "http"
        backend_pool_name = "web-servers"
        probe_name = "http-health"
        protocol = "Tcp"
        frontend_port = 80
        backend_port = 80
        enable_floating_ip = false
        idle_timeout_in_minutes = 4
        load_distribution = "Default"
        disable_outbound_snat = false
        enable_tcp_reset = true
      }]

      nat_rules = []
      outbound_rules = []
      tags = {}
    }
  }
}
```
