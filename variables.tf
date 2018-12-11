variable "resource_group_name" {}
variable "location" {}
variable "StorageAccountName" {}
variable "vmsize" {}
variable "fgtvmsize" {}
variable "adminUsername" {}
variable "adminPassword" {}

variable "storageAccountType" {
  default = "Standard_LRS"
}
