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

resource "azurerm_public_ip" "fgvm01-pip" {
  name                         = "fgvm01-pip"
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

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "10.20.2.0/24"
  }

  security_rule {
    name                       = "HTTPS"
    priority                   = 1002
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "10.20.2.0/24"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1003
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "10.20.2.0/24"
  }

  security_rule {
    name                       = "ToFrontendOut"
    priority                   = 1005
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "10.20.2.0/24"
  }

  security_rule {
    name                       = "FromInternalLBIn"
    priority                   = 1006
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.20.1.10/32"
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

  route {
    name                   = "ProtectedNetwork"
    address_prefix         = "10.20.0.0/16"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.20.2.100"
  }
}



resource "azurerm_subnet_route_table_association" "internal_route" {
  subnet_id      = "${azurerm_subnet.internal.id}"
  route_table_id = "${azurerm_route_table.InternalToExternalLB.id}"
}


