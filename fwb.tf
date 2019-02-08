resource "azurerm_network_interface" "FortiWebVM-nic01" {
  name                = "FortiWebVM-nic02"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.resourcegroup.name}"
  depends_on          = ["azurerm_virtual_network.frontend"]

  ip_configuration {
    name                          = "${join("", list("ipconfig", "1"))}"
    subnet_id                     = "${azurerm_subnet.external.id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "10.20.1.100"
    public_ip_address_id          = "${azurerm_public_ip.fwbvm01-pip.id}"
  }

  enable_ip_forwarding = "true"

  enable_accelerated_networking = "true"
}

resource "azurerm_network_interface" "FortiWebVM-nic02" {
  name                = "FortiWebVM-nic03"
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

}

resource "azurerm_virtual_machine" "fwbvm01" {
  name                = "FWBVM01"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.resourcegroup.name}"
  vm_size             = "${var.fgtvmsize}"

  storage_os_disk {
    name              = "fwbm01-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "fortinet"
    offer     = "fortinet_fortiweb-vm_v5"
    sku       = "fortinet_fw-vm_payg"
    version   = "6.0.2"
  }

  # plan information required for marketplace images
  plan {
    name      = "fortinet_fw-vm_payg"
    product   = "fortinet_fortiweb-vm_v5"
    publisher = "fortinet"
  }

  storage_data_disk {
    name              = "fwbm01-datasdisk"
    managed_disk_type = "Standard_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "30"
  }

  os_profile {
    computer_name  = "FWBVM01"
    admin_username = "${var.adminUsername}"
    admin_password = "${var.adminPassword}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  network_interface_ids        = ["${azurerm_network_interface.FortiWebVM-nic01.id}", "${azurerm_network_interface.FortiWebVM-nic02.id}"]
  primary_network_interface_id = "${azurerm_network_interface.FortiWebVM-nic01.id}"
}
