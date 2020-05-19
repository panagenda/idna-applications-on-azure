data "azurerm_subnet" "ifa" {
  name                 = var.subnet
  count                = var.subnet == "" ? 0 : 1
  virtual_network_name = var.vnet
  resource_group_name  = var.rg
}

# creates nic
resource "azurerm_network_interface" "ifa" {
  name                      = "${var.prefix}-nic"
  count                     = var.subnet == "" ? 0 : 1
  location                  = azurerm_resource_group.ifa.location
  resource_group_name       = azurerm_resource_group.ifa.name

  ip_configuration {
    name                          = "${var.prefix}-nic"
    subnet_id                     = data.azurerm_subnet.ifa[0].id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.ip
  }
}