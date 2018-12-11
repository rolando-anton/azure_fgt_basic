resource "azurerm_network_interface" "webserver-nic" {
    name                = "webserver-nic"
    location            = "${var.location}"
    resource_group_name  = "${azurerm_resource_group.resourcegroup.name}"
    ip_configuration {
        name = "${join("", list("ipconfig", "0"))}"
        subnet_id = "${azurerm_subnet.internal.id}"
        private_ip_address_allocation = "static"
        private_ip_address = "10.20.2.200" 
    }
}

resource "azurerm_virtual_machine" "webserver" {
    name                  = "webserver"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.resourcegroup.name}"
  vm_size               = "${var.vmsize}"
 depends_on          = ["azurerm_virtual_machine.fgvm01"]



    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    storage_os_disk {
        name          = "webserver-osdisk"
        caching       = "ReadWrite"
        create_option = "FromImage"
        managed_disk_type = "Standard_LRS"
    }


    os_profile {
        computer_name  = "webserver"
        admin_username = "${var.adminUsername}"
        admin_password = "${var.adminPassword}"
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }
    network_interface_ids = ["${azurerm_network_interface.webserver-nic.id}"]

}



resource "azurerm_virtual_machine_extension" "post-web" {
  name                 = "web-vm-customscript"
  location             = "${var.location}"
  resource_group_name  = "${azurerm_resource_group.resourcegroup.name}"
  virtual_machine_name = "${azurerm_virtual_machine.webserver.name}"  
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "apt -y update && apt -y upgrade && apt -y install nginx"
    }
SETTINGS
}

