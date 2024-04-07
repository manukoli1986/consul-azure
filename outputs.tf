output "consul_servers" {
  value = azurerm_linux_virtual_machine.server.*.public_ip_address
}

# output "consul_agetns" {
#   value = azurerm_linux_virtual_machine.agents.*.public_ip_address
# }