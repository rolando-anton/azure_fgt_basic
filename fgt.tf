resource "azurerm_network_interface" "FortiGateVM-nic01" {
  name                = "FortiGateVM-nic02"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.resourcegroup.name}"
  depends_on          = ["azurerm_virtual_network.frontend"]

  ip_configuration {
    name                          = "${join("", list("ipconfig", "1"))}"
    subnet_id                     = "${azurerm_subnet.external.id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "10.20.1.100"
    public_ip_address_id = "${azurerm_public_ip.fgvm01-pip.id}"

  }

  enable_ip_forwarding = "true"

  enable_accelerated_networking = "true"
}

resource "azurerm_network_interface" "FortiGateVM-nic02" {
  name                = "FortiGateVM-nic03"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.resourcegroup.name}"
  depends_on          = ["azurerm_virtual_network.frontend"]

  ip_configuration {
    name                          = "${join("", list("ipconfig", "2"))}"
    subnet_id                     = "${azurerm_subnet.internal.id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "10.20.2.100"
  }

  enable_ip_forwarding = "true"

  enable_accelerated_networking = "true"
}

resource "azurerm_virtual_machine" "fgvm01" {
  name                = "FGVM01"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.resourcegroup.name}"
  vm_size             = "${var.fgtvmsize}"

  storage_os_disk {
    name              = "fgvm01-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "fortinet"
    offer     = "fortinet_fortigate-vm_v5"
    sku       = "fortinet_fg-vm_payg"
    version   = "6.0.3"
  }

  # plan information required for marketplace images
  plan {
    name      = "fortinet_fg-vm_payg"
    product   = "fortinet_fortigate-vm_v5"
    publisher = "fortinet"
  }

  storage_data_disk {
    name              = "fgvm01-datasdisk"
    managed_disk_type = "Standard_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "30"
  }

  os_profile {
    computer_name  = "FGVM01"
    admin_username = "${var.adminUsername}"
    admin_password = "${var.adminPassword}"
    custom_data = <<CUSTOMDATA
   config system interface
   	edit "port2"
        set vdom "root"
        set mode dhcp
        set type physical
        set snmp-index 2
        set defaultgw disable
        set dns-server-override disable
   end
   config firewall policy
    	edit 1
        	set name "toinet"
        	set srcintf "port2"
        	set dstintf "port1"
        	set srcaddr "all"
        	set dstaddr "all"
        	set action accept
        	set schedule "always"
        	set service "ALL"
        	set logtraffic all
        	set nat enable
    		next
	end


    CUSTOMDATA
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  network_interface_ids        = ["${azurerm_network_interface.FortiGateVM-nic01.id}", "${azurerm_network_interface.FortiGateVM-nic02.id}"]
  primary_network_interface_id = "${azurerm_network_interface.FortiGateVM-nic01.id}"
}
