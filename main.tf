provider "azurerm" {}

resource "azurerm_resource_group" "resourcegroup" {
  name     = "${var.resource_group_name}"
  location = "${var.location}"
}

resource "azurerm_storage_account" "fgt_storage_acc" {
  name                     = "${var.StorageAccountName}"
  resource_group_name      = "${azurerm_resource_group.resourcegroup.name}"
  location                 = "${var.location}"
  account_replication_type = "LRS"
  account_tier             = "Standard"
}
