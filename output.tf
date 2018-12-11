output "FGT01_MGMT" {
  value = "${join("", list("https://", "${azurerm_public_ip.fgvm01-mgmt.ip_address}"))}"
}

output "FGT02_MGMT" {
  value = "${join("", list("https://", "${azurerm_public_ip.fgvm02-mgmt.ip_address}"))}"
}

output "FGT01_PUB" {
  value = "${join("", list("https://", "${azurerm_public_ip.fgvm01-pip.ip_address}"))}"
}

output "FGT02_PUB" {
  value = "${join("", list("https://", "${azurerm_public_ip.fgvm02-pip.ip_address}"))}"
}

output "FMG_MGMT" {
  value = "${join("", list("https://", "${azurerm_public_ip.fmg-mgmt.ip_address}"))}"
}
