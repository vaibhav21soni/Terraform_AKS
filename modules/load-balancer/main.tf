# Load Balancer Module
# Creates and manages Azure Load Balancers (Public and Internal)

# Public IP for Public Load Balancer
resource "azurerm_public_ip" "main" {
  for_each = {
    for lb_key, lb_config in var.load_balancers : lb_key => lb_config
    if lb_config.type == "public"
  }

  name                = "${each.key}-${var.environment}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = each.value.public_ip_allocation_method
  sku                 = each.value.public_ip_sku
  zones               = each.value.availability_zones

  domain_name_label = each.value.domain_name_label

  tags = merge(var.tags, each.value.tags)
}

# Load Balancer
resource "azurerm_lb" "main" {
  for_each = var.load_balancers

  name                = "${each.key}-${var.environment}-lb"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = each.value.sku
  sku_tier            = each.value.sku_tier

  dynamic "frontend_ip_configuration" {
    for_each = each.value.type == "public" ? [1] : []
    content {
      name                 = "${each.key}-public-frontend"
      public_ip_address_id = azurerm_public_ip.main[each.key].id
    }
  }

  dynamic "frontend_ip_configuration" {
    for_each = each.value.type == "internal" ? [1] : []
    content {
      name                          = "${each.key}-internal-frontend"
      subnet_id                     = each.value.subnet_id
      private_ip_address_allocation = each.value.private_ip_address_allocation
      private_ip_address            = each.value.private_ip_address
      private_ip_address_version    = each.value.private_ip_address_version
      zones                         = each.value.availability_zones
    }
  }

  tags = merge(var.tags, each.value.tags)
}

# Backend Address Pool
resource "azurerm_lb_backend_address_pool" "main" {
  for_each = {
    for pool in flatten([
      for lb_key, lb_config in var.load_balancers : [
        for pool in lb_config.backend_pools : {
          key           = "${lb_key}-${pool.name}"
          lb_key        = lb_key
          name          = pool.name
          loadbalancer_id = azurerm_lb.main[lb_key].id
        }
      ]
    ]) : pool.key => pool
  }

  name            = each.value.name
  loadbalancer_id = each.value.loadbalancer_id
}

# Health Probe
resource "azurerm_lb_probe" "main" {
  for_each = {
    for probe in flatten([
      for lb_key, lb_config in var.load_balancers : [
        for probe in lb_config.health_probes : {
          key             = "${lb_key}-${probe.name}"
          lb_key          = lb_key
          name            = probe.name
          loadbalancer_id = azurerm_lb.main[lb_key].id
          protocol        = probe.protocol
          port            = probe.port
          request_path    = probe.request_path
          interval_in_seconds = probe.interval_in_seconds
          number_of_probes = probe.number_of_probes
        }
      ]
    ]) : probe.key => probe
  }

  name            = each.value.name
  loadbalancer_id = each.value.loadbalancer_id
  protocol        = each.value.protocol
  port            = each.value.port
  request_path    = each.value.protocol == "Http" || each.value.protocol == "Https" ? each.value.request_path : null
  interval_in_seconds = each.value.interval_in_seconds
  number_of_probes = each.value.number_of_probes
}

# Load Balancing Rule
resource "azurerm_lb_rule" "main" {
  for_each = {
    for rule in flatten([
      for lb_key, lb_config in var.load_balancers : [
        for rule in lb_config.load_balancing_rules : {
          key                           = "${lb_key}-${rule.name}"
          lb_key                        = lb_key
          name                          = rule.name
          loadbalancer_id               = azurerm_lb.main[lb_key].id
          frontend_ip_configuration_name = lb_config.type == "public" ? "${lb_key}-public-frontend" : "${lb_key}-internal-frontend"
          backend_address_pool_ids      = [azurerm_lb_backend_address_pool.main["${lb_key}-${rule.backend_pool_name}"].id]
          probe_id                      = rule.probe_name != null ? azurerm_lb_probe.main["${lb_key}-${rule.probe_name}"].id : null
          protocol                      = rule.protocol
          frontend_port                 = rule.frontend_port
          backend_port                  = rule.backend_port
          enable_floating_ip            = rule.enable_floating_ip
          idle_timeout_in_minutes       = rule.idle_timeout_in_minutes
          load_distribution             = rule.load_distribution
          disable_outbound_snat         = rule.disable_outbound_snat
          enable_tcp_reset              = rule.enable_tcp_reset
        }
      ]
    ]) : rule.key => rule
  }

  name                           = each.value.name
  loadbalancer_id                = each.value.loadbalancer_id
  frontend_ip_configuration_name = each.value.frontend_ip_configuration_name
  backend_address_pool_ids       = each.value.backend_address_pool_ids
  probe_id                       = each.value.probe_id
  protocol                       = each.value.protocol
  frontend_port                  = each.value.frontend_port
  backend_port                   = each.value.backend_port
  enable_floating_ip             = each.value.enable_floating_ip
  idle_timeout_in_minutes        = each.value.idle_timeout_in_minutes
  load_distribution              = each.value.load_distribution
  disable_outbound_snat          = each.value.disable_outbound_snat
  enable_tcp_reset               = each.value.enable_tcp_reset
}

# NAT Rule
resource "azurerm_lb_nat_rule" "main" {
  for_each = {
    for nat_rule in flatten([
      for lb_key, lb_config in var.load_balancers : [
        for nat_rule in lb_config.nat_rules : {
          key                           = "${lb_key}-${nat_rule.name}"
          lb_key                        = lb_key
          name                          = nat_rule.name
          loadbalancer_id               = azurerm_lb.main[lb_key].id
          frontend_ip_configuration_name = lb_config.type == "public" ? "${lb_key}-public-frontend" : "${lb_key}-internal-frontend"
          protocol                      = nat_rule.protocol
          frontend_port                 = nat_rule.frontend_port
          backend_port                  = nat_rule.backend_port
          enable_floating_ip            = nat_rule.enable_floating_ip
          enable_tcp_reset              = nat_rule.enable_tcp_reset
          idle_timeout_in_minutes       = nat_rule.idle_timeout_in_minutes
        }
      ]
    ]) : nat_rule.key => nat_rule
  }

  name                           = each.value.name
  resource_group_name            = var.resource_group_name
  loadbalancer_id                = each.value.loadbalancer_id
  frontend_ip_configuration_name = each.value.frontend_ip_configuration_name
  protocol                       = each.value.protocol
  frontend_port                  = each.value.frontend_port
  backend_port                   = each.value.backend_port
  enable_floating_ip             = each.value.enable_floating_ip
  enable_tcp_reset               = each.value.enable_tcp_reset
  idle_timeout_in_minutes        = each.value.idle_timeout_in_minutes
}

# Outbound Rule (for Standard SKU)
resource "azurerm_lb_outbound_rule" "main" {
  for_each = {
    for outbound_rule in flatten([
      for lb_key, lb_config in var.load_balancers : [
        for outbound_rule in lb_config.outbound_rules : {
          key                           = "${lb_key}-${outbound_rule.name}"
          lb_key                        = lb_key
          name                          = outbound_rule.name
          loadbalancer_id               = azurerm_lb.main[lb_key].id
          frontend_ip_configuration     = [{
            name = lb_config.type == "public" ? "${lb_key}-public-frontend" : "${lb_key}-internal-frontend"
          }]
          backend_address_pool_id       = azurerm_lb_backend_address_pool.main["${lb_key}-${outbound_rule.backend_pool_name}"].id
          protocol                      = outbound_rule.protocol
          enable_tcp_reset              = outbound_rule.enable_tcp_reset
          allocated_outbound_ports      = outbound_rule.allocated_outbound_ports
          idle_timeout_in_minutes       = outbound_rule.idle_timeout_in_minutes
        }
      ]
    ]) : outbound_rule.key => outbound_rule
  }

  name                     = each.value.name
  loadbalancer_id          = each.value.loadbalancer_id
  backend_address_pool_id  = each.value.backend_address_pool_id
  protocol                 = each.value.protocol
  enable_tcp_reset         = each.value.enable_tcp_reset
  allocated_outbound_ports = each.value.allocated_outbound_ports
  idle_timeout_in_minutes  = each.value.idle_timeout_in_minutes

  dynamic "frontend_ip_configuration" {
    for_each = each.value.frontend_ip_configuration
    content {
      name = frontend_ip_configuration.value.name
    }
  }
}

# Backend Address Pool Address (for specific VM assignments)
resource "azurerm_lb_backend_address_pool_address" "main" {
  for_each = {
    for address in flatten([
      for lb_key, lb_config in var.load_balancers : [
        for pool in lb_config.backend_pools : [
          for address in pool.addresses : {
            key                     = "${lb_key}-${pool.name}-${address.name}"
            name                    = address.name
            backend_address_pool_id = azurerm_lb_backend_address_pool.main["${lb_key}-${pool.name}"].id
            virtual_network_id      = address.virtual_network_id
            ip_address              = address.ip_address
          }
        ]
      ]
    ]) : address.key => address
  }

  name                    = each.value.name
  backend_address_pool_id = each.value.backend_address_pool_id
  virtual_network_id      = each.value.virtual_network_id
  ip_address              = each.value.ip_address
}
