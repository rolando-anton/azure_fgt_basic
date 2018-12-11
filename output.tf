output "FGT_PUB" {
  value = "${join("", list("https://", "${azurerm_public_ip.fgvm01-pip.ip_address}"))}"
}
