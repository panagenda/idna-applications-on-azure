# public ip
output "public_ip_address" {
  value = length(azurerm_public_ip.ifa) > 0 ? azurerm_public_ip.ifa[0].ip_address : ""
}

# private ip
output "private_ip_address" {
  value = length(azurerm_network_interface.ifa) > 0 ? azurerm_network_interface.ifa[0].ip_configuration[0].private_ip_address : ""
}

# the configured resource group -> will be used by scripts
output "resource_group" {
  value = var.resource_group_name
}

# the configured location -> will be used by scripts
output "location" {
  value = var.location
}

# the configured location -> will be used by scripts
output "prefix" {
  value = var.prefix
}
