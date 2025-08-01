output "load_balancers" {
  description = "Map of created load balancers"
  value = {
    for k, v in azurerm_lb.main : k => {
      id                        = v.id
      name                      = v.name
      sku                       = v.sku
      sku_tier                  = v.sku_tier
      frontend_ip_configuration = v.frontend_ip_configuration
      private_ip_address        = length(v.frontend_ip_configuration) > 0 ? v.frontend_ip_configuration[0].private_ip_address : null
      private_ip_addresses      = v.private_ip_addresses
    }
  }
}

output "public_ips" {
  description = "Map of created public IPs"
  value = {
    for k, v in azurerm_public_ip.main : k => {
      id                = v.id
      name              = v.name
      ip_address        = v.ip_address
      fqdn              = v.fqdn
      domain_name_label = v.domain_name_label
    }
  }
}

output "backend_address_pools" {
  description = "Map of created backend address pools"
  value = {
    for k, v in azurerm_lb_backend_address_pool.main : k => {
      id                = v.id
      name              = v.name
      loadbalancer_id   = v.loadbalancer_id
      backend_addresses = v.backend_addresses
    }
  }
}

output "health_probes" {
  description = "Map of created health probes"
  value = {
    for k, v in azurerm_lb_probe.main : k => {
      id                  = v.id
      name                = v.name
      protocol            = v.protocol
      port                = v.port
      request_path        = v.request_path
      interval_in_seconds = v.interval_in_seconds
      number_of_probes    = v.number_of_probes
    }
  }
}

output "load_balancing_rules" {
  description = "Map of created load balancing rules"
  value = {
    for k, v in azurerm_lb_rule.main : k => {
      id                             = v.id
      name                           = v.name
      protocol                       = v.protocol
      frontend_port                  = v.frontend_port
      backend_port                   = v.backend_port
      frontend_ip_configuration_name = v.frontend_ip_configuration_name
      backend_address_pool_ids       = v.backend_address_pool_ids
      probe_id                       = v.probe_id
      enable_floating_ip             = v.enable_floating_ip
      idle_timeout_in_minutes        = v.idle_timeout_in_minutes
      load_distribution              = v.load_distribution
      disable_outbound_snat          = v.disable_outbound_snat
      enable_tcp_reset               = v.enable_tcp_reset
    }
  }
}

output "nat_rules" {
  description = "Map of created NAT rules"
  value = {
    for k, v in azurerm_lb_nat_rule.main : k => {
      id                             = v.id
      name                           = v.name
      protocol                       = v.protocol
      frontend_port                  = v.frontend_port
      backend_port                   = v.backend_port
      frontend_ip_configuration_name = v.frontend_ip_configuration_name
      enable_floating_ip             = v.enable_floating_ip
      enable_tcp_reset               = v.enable_tcp_reset
      idle_timeout_in_minutes        = v.idle_timeout_in_minutes
    }
  }
}

output "outbound_rules" {
  description = "Map of created outbound rules"
  value = {
    for k, v in azurerm_lb_outbound_rule.main : k => {
      id                       = v.id
      name                     = v.name
      protocol                 = v.protocol
      backend_address_pool_id  = v.backend_address_pool_id
      frontend_ip_configuration = v.frontend_ip_configuration
      enable_tcp_reset         = v.enable_tcp_reset
      allocated_outbound_ports = v.allocated_outbound_ports
      idle_timeout_in_minutes  = v.idle_timeout_in_minutes
    }
  }
}

output "backend_pool_addresses" {
  description = "Map of created backend pool addresses"
  value = {
    for k, v in azurerm_lb_backend_address_pool_address.main : k => {
      id                      = v.id
      name                    = v.name
      backend_address_pool_id = v.backend_address_pool_id
      virtual_network_id      = v.virtual_network_id
      ip_address              = v.ip_address
    }
  }
}
