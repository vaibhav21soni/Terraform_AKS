variable "environment" {
  description = "Environment name"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "load_balancers" {
  description = "Map of load balancers to create"
  type = map(object({
    type                           = string # "public" or "internal"
    sku                           = string # "Basic" or "Standard"
    sku_tier                      = string # "Regional" or "Global"
    subnet_id                     = string # Required for internal LB
    private_ip_address_allocation = string # "Static" or "Dynamic"
    private_ip_address            = string # Required if allocation is "Static"
    private_ip_address_version    = string # "IPv4" or "IPv6"
    availability_zones            = list(string)
    
    # Public IP configuration (for public LB)
    public_ip_allocation_method = string # "Static" or "Dynamic"
    public_ip_sku              = string # "Basic" or "Standard"
    domain_name_label          = string

    # Backend pools
    backend_pools = list(object({
      name = string
      addresses = list(object({
        name               = string
        virtual_network_id = string
        ip_address         = string
      }))
    }))

    # Health probes
    health_probes = list(object({
      name                = string
      protocol            = string # "Http", "Https", or "Tcp"
      port                = number
      request_path        = string # Required for Http/Https
      interval_in_seconds = number
      number_of_probes    = number
    }))

    # Load balancing rules
    load_balancing_rules = list(object({
      name                    = string
      backend_pool_name       = string
      probe_name              = string
      protocol                = string # "Tcp", "Udp", or "All"
      frontend_port           = number
      backend_port            = number
      enable_floating_ip      = bool
      idle_timeout_in_minutes = number
      load_distribution       = string # "Default", "SourceIP", or "SourceIPProtocol"
      disable_outbound_snat   = bool
      enable_tcp_reset        = bool
    }))

    # NAT rules
    nat_rules = list(object({
      name                    = string
      protocol                = string # "Tcp" or "Udp"
      frontend_port           = number
      backend_port            = number
      enable_floating_ip      = bool
      enable_tcp_reset        = bool
      idle_timeout_in_minutes = number
    }))

    # Outbound rules (Standard SKU only)
    outbound_rules = list(object({
      name                     = string
      backend_pool_name        = string
      protocol                 = string # "Tcp", "Udp", or "All"
      enable_tcp_reset         = bool
      allocated_outbound_ports = number
      idle_timeout_in_minutes  = number
    }))

    tags = map(string)
  }))
  default = {}
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}
