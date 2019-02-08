# VNET definition

resource "azurerm_virtual_network" "frontend" {
  name                = "SecureVNET"
  address_space       = ["10.20.0.0/16"]
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.resourcegroup.name}"
}

# Subnet deffinitions

resource "azurerm_subnet" "external" {
  name                 = "external"
  resource_group_name  = "${azurerm_resource_group.resourcegroup.name}"
  virtual_network_name = "${azurerm_virtual_network.frontend.name}"
  address_prefix       = "10.20.1.0/24"
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = "${azurerm_resource_group.resourcegroup.name}"
  virtual_network_name = "${azurerm_virtual_network.frontend.name}"
  address_prefix       = "10.20.2.0/24"
}

# Public IPs for publications

resource "azurerm_public_ip" "fwbvm01-pip" {
  name                         = "fwbvm01-pip"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.resourcegroup.name}"
  public_ip_address_allocation = "static"
  sku                          = "Standard"
}

resource "azurerm_network_security_group" "nsg-external" {
  name                = "nsg-external"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.resourcegroup.name}"

  security_rule {
    name                       = "AllowAllInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowOutAll"
    priority                   = 101
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "nsg-internal" {
  name                = "nsg-internal"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.resourcegroup.name}"

  security_rule {
    name                       = "AllowInAll"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowOutAll"
    priority                   = 101
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Security Groups mapping

resource "azurerm_subnet_network_security_group_association" "secgroup2internal" {
  subnet_id                 = "${azurerm_subnet.internal.id}"
  network_security_group_id = "${azurerm_network_security_group.nsg-internal.id}"
}

resource "azurerm_subnet_network_security_group_association" "secgroup2external" {
  subnet_id                 = "${azurerm_subnet.external.id}"
  network_security_group_id = "${azurerm_network_security_group.nsg-external.id}"
}

# route tables

resource "azurerm_route_table" "InternalToExternalLB" {
  name                = "front2internalLB"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.resourcegroup.name}"

  route {
    name                   = "route-to-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.20.2.100"
  }
}

resource "azurerm_subnet_route_table_association" "internal_route" {
  subnet_id      = "${azurerm_subnet.internal.id}"
  route_table_id = "${azurerm_route_table.InternalToExternalLB.id}"
}


resource "azurerm_application_gateway" "appgw" {
    name                = "${azurerm_virtual_network.frontend.name}"
    location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.resourcegroup.name}"
    sku {
        name           = "Standard_Small"
        tier           = "Standard"
        capacity       = 2
    }
    gateway_ip_configuration {
        name         = "${azurerm_virtual_network.frontend.name}-gwip-cfg"
  subnet_id      = "${azurerm_subnet.internal.id}"
    }
    frontend_port {
        name         = "${azurerm_virtual_network.frontend.name}-feport"
        port         = 80
    }
    frontend_ip_configuration {
        name         = "${azurerm_virtual_network.frontend.name}-gwip-feip"  
        private_ip_address_id = "${azurerm_public_ip.pip.id}"
        subnet_id      = "${azurerm_subnet.internal.id}"
        private_ip_address_allocation = "dynamic"
    }

    backend_address_pool {
        name = "${azurerm_virtual_network.frontend.name}-beap"
        ip_address_list = ["${element(azurerm_network_interface.nic.*.private_ip_address, count.index)}"] 
    }
    backend_http_settings {
        name                  = "${azurerm_virtual_network.frontend.name}-be-htst"
        cookie_based_affinity = "Disabled"
        port                  = 80
        protocol              = "Http"
        request_timeout        = 1
    }
    http_listener {
        name                                  = "${azurerm_virtual_network.frontend.name}-httplstn"
        frontend_ip_configuration_name        = "${azurerm_virtual_network.frontend.name}-feip"
        frontend_port_name                    = "${azurerm_virtual_network.frontend.name}-feport"
        protocol                              = "Http"
    }
    request_routing_rule {
        name                       = "${azurerm_virtual_network.frontend.name}-rqrt"
        rule_type                  = "Basic"
        http_listener_name         = "${azurerm_virtual_network.frontend.name}-httplstn"
        backend_address_pool_name  = "${azurerm_virtual_network.frontend.name}-beap"
        backend_http_settings_name = "${azurerm_virtual_network.frontend.name}-be-htst"
    }
}

resource "azurerm_app_service_plan" "dvwa" {
  name                = "dvwa-plan"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.resourcegroup.name}"

  sku {
    tier = "Free"
    size = "F1"
  }
}

resource "azurerm_app_service" "dvwa" {
  name                = "dvwa-app"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.resourcegroup.name}"
  app_service_plan_id = "${azurerm_app_service_plan.dvwa.id}"
  site_config {
    php_version = "7.2"  }
}