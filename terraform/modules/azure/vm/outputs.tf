output "ips" {
  value = zipmap(azurerm_linux_virtual_machine.vm.*.name, chunklist(azurerm_public_ip.pip.*.ip_address, 1))
}
